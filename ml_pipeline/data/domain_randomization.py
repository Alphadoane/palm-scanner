import numpy as np
import cv2

def skin_reflectance(image):
    """
    Simulates skin light diffusion
    """
    blurred = cv2.GaussianBlur(image, (21, 21), 0)
    # mix high-frequency + low-frequency components
    return 0.7 * image + 0.3 * blurred

def directional_light(image):
    h, w = image.shape[:2]
    x = np.linspace(0, 1, w)
    y = np.linspace(0, 1, h)
    xv, yv = np.meshgrid(x, y)
    gradient = 0.6 + 0.4 * (xv * np.random.uniform(0.5, 1.5))
    
    # Handle single channel or RGB
    if len(image.shape) == 3:
        gradient = np.stack([gradient]*3, axis=-1)
        
    return np.clip(image * gradient, 0, 255)

def color_temperature_shift(image):
    if len(image.shape) < 3:
        return image # Only apply to RGB
    temp = np.random.uniform(3000, 9000)
    r_gain = 1.0 + (6500 - temp) / 6500
    b_gain = 1.0 + (temp - 6500) / 6500
    image = image.astype(np.float32)
    image[..., 0] *= r_gain
    image[..., 2] *= b_gain
    return np.clip(image, 0, 255)

def sensor_noise(image):
    noise_sigma = np.random.uniform(2, 12)
    noise = np.random.normal(0, noise_sigma, image.shape)
    return np.clip(image + noise, 0, 255)

def motion_blur(image):
    size = np.random.randint(3, 9)
    kernel = np.zeros((size, size))
    kernel[int((size-1)/2), :] = np.ones(size)
    kernel = kernel / size
    return cv2.filter2D(image, -1, kernel)

def depth_of_field(image):
    blur = np.random.uniform(1, 5)
    return cv2.GaussianBlur(image, (0,0), blur)

def lens_distortion(image):
    h, w = image.shape[:2]
    k = np.random.uniform(-0.2, 0.2)
    map_x, map_y = np.meshgrid(np.arange(w), np.arange(h))
    cx, cy = w/2, h/2
    x = (map_x - cx) / w
    y = (map_y - cy) / h
    r2 = x**2 + y**2
    factor = 1 + k * r2
    map_x = (x * factor * w + cx).astype(np.float32)
    map_y = (y * factor * h + cy).astype(np.float32)
    return cv2.remap(image, map_x, map_y, cv2.INTER_LINEAR)

def jpeg_artifacts(image):
    quality = np.random.randint(30, 95)
    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), quality]
    _, encimg = cv2.imencode('.jpg', image, encode_param)
    decimg = cv2.imdecode(encimg, 1)
    
    # Re-convert to grayscale if input was grayscale
    if len(image.shape) == 2 and len(decimg.shape) == 3:
        decimg = cv2.cvtColor(decimg, cv2.COLOR_BGR2GRAY)
        
    return decimg

def domain_randomize(image):
    image = skin_reflectance(image)
    image = directional_light(image)
    image = color_temperature_shift(image)
    image = sensor_noise(image)
    if np.random.rand() > 0.5:
        image = motion_blur(image)
    image = depth_of_field(image)
    image = lens_distortion(image)
    image = jpeg_artifacts(image.astype(np.uint8))
    return np.clip(image, 0, 255).astype(np.uint8)
