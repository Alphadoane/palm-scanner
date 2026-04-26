import numpy as np
import cv2

# Define anatomical zones for 15 lines (scaled to size)
LINE_DEFS = {
    "life_line": {"start": (50, 150), "end": (128, 250), "prob": 1.0},
    "head_line": {"start": (50, 150), "end": (220, 150), "prob": 1.0},
    "heart_line": {"start": (220, 80), "end": (50, 80), "prob": 1.0},
    "fate_line": {"start": (128, 250), "end": (128, 100), "prob": 0.6},
    "sun_line": {"start": (180, 200), "end": (180, 80), "prob": 0.4},
    "health_line": {"start": (128, 250), "end": (220, 100), "prob": 0.4},
    "marriage_line": {"start": (250, 90), "end": (220, 90), "prob": 0.7},
    "money_line": {"start": (100, 180), "end": (150, 120), "prob": 0.3},
    "travel_lines": {"start": (250, 200), "end": (220, 200), "prob": 0.5},
    "girdle_of_venus": {"start": (80, 70), "end": (180, 70), "type": "arc", "prob": 0.3},
    "ring_of_solomon": {"center": (60, 50), "type": "ring", "prob": 0.2},
    "ring_of_saturn": {"center": (110, 45), "type": "ring", "prob": 0.1},
    "ring_of_apollo": {"center": (160, 45), "type": "ring", "prob": 0.1},
    "ring_of_mercury": {"center": (210, 50), "type": "ring", "prob": 0.1},
    "bracelet_lines": {"start": (50, 260), "end": (200, 260), "prob": 0.9}
}

def bezier_curve(p0, p1, p2, p3, t):
    return (
        (1-t)**3 * p0 +
        3*(1-t)**2*t * p1 +
        3*(1-t)*t**2 * p2 +
        t**3 * p3
    )

def generate_line(start, end, resolution=100, scale=1.0):
    p0 = np.array(start) * scale
    p3 = np.array(end) * scale
    # random control points for natural variation
    mid = (p0 + p3) / 2
    p1 = mid + np.random.normal(0, 15 * scale, 2)
    p2 = mid + np.random.normal(0, 15 * scale, 2)
    
    curve = []
    for t in np.linspace(0, 1, resolution):
        curve.append(bezier_curve(p0, p1, p2, p3, t))
    return np.array(curve)

def generate_arc(start, end, resolution=100, scale=1.0):
    p0 = np.array(start) * scale
    p3 = np.array(end) * scale
    mid = (p0 + p3) / 2
    # Pull the middle up to create an arc
    p1 = mid + np.array([0, -30 * scale]) + np.random.normal(0, 5 * scale, 2)
    p2 = p1.copy()
    
    curve = []
    for t in np.linspace(0, 1, resolution):
        curve.append(bezier_curve(p0, p1, p2, p3, t))
    return np.array(curve)

def generate_ring(center, radius=15, resolution=50, scale=1.0):
    c = np.array(center) * scale
    r = radius * scale
    curve = []
    # Half-circle arc
    for theta in np.linspace(np.pi, 2*np.pi, resolution):
        x = c[0] + r * np.cos(theta)
        y = c[1] + r * np.sin(theta) + r/2
        curve.append([x, y])
    return np.array(curve)

def render_skeleton(curves, size=256):
    canvas = np.zeros((size, size), dtype=np.uint8)
    for curve in curves:
        for p in curve:
            x, y = int(p[0]), int(p[1])
            if 0 <= x < size and 0 <= y < size:
                canvas[y, x] = 255
    kernel = np.ones((3,3), np.uint8)
    canvas = cv2.dilate(canvas, kernel, iterations=1)
    return canvas

def generate_palm_background(size=256):
    base = np.random.normal(180, 10, (size, size))
    noise = cv2.GaussianBlur(base, (9,9), 0)
    return np.clip(noise, 0, 255).astype(np.uint8)

def render_palm_image(background, skeleton):
    image = background.copy()
    image[skeleton > 0] = image[skeleton > 0] * 0.4 # Darken lines
    return image

def generate_sample(size=256):
    scale = size / 256.0
    curves_data = []
    
    for name, defs in LINE_DEFS.items():
        if np.random.rand() > defs.get("prob", 1.0):
            continue
            
        if defs.get("type") == "ring":
            pts = generate_ring(defs["center"], scale=scale)
        elif defs.get("type") == "arc":
            pts = generate_arc(defs["start"], defs["end"], scale=scale)
        else:
            pts = generate_line(defs["start"], defs["end"], scale=scale)
            
        curves_data.append({"points": pts, "type": name})
    
    skeleton = render_skeleton([c["points"] for c in curves_data], size)
    background = generate_palm_background(size)
    image = render_palm_image(background, skeleton)
    
    masks = {name: np.zeros((size, size)) for name in LINE_DEFS.keys()}
    for c in curves_data:
        for p in c["points"]:
            x, y = int(p[0]), int(p[1])
            if 0 <= x < size and 0 <= y < size:
                masks[c["type"]][y, x] = 1
                
    return {
        "image": image,
        "skeleton": skeleton,
        "masks": masks
    }

if __name__ == "__main__":
    sample = generate_sample(256)
    print(f"Generated sample with {len(sample['masks'])} mask channels.")
