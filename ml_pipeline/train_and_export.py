import os
import sys
import numpy as np
import tensorflow as tf

# Ensure ml_pipeline is in the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from data.synthetic_generator import generate_sample, LINE_DEFS
from data.domain_randomization import domain_randomize
from models.attention_unet_aspp import build_attention_unet_aspp
from models.losses import dice_loss

# --- MEMORY OPTIMIZATION ---
def setup_gpu_memory():
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        try:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"Set memory growth for {len(gpus)} GPU(s)")
        except RuntimeError as e:
            print(f"GPU memory growth error: {e}")

class PalmDataGenerator(tf.keras.utils.Sequence):
    def __init__(self, num_samples=100, batch_size=2, size=224, shuffle=True):
        self.num_samples = num_samples
        self.batch_size = batch_size
        self.size = size
        self.shuffle = shuffle
        self.line_names = list(LINE_DEFS.keys())
        self.on_epoch_end()

    def __len__(self):
        return int(np.floor(self.num_samples / self.batch_size))

    def on_epoch_end(self):
        pass

    def __getitem__(self, index):
        images = []
        masks = []
        
        for _ in range(self.batch_size):
            sample = generate_sample(size=self.size)
            
            # Image processing
            img = sample["image"]
            img = np.expand_dims(img, axis=-1)
            img = np.repeat(img, 3, axis=-1) 
            img = domain_randomize(img)
            img = img / 255.0 
            
            # Mask processing (16 channels)
            mask_channels = []
            for name in self.line_names:
                mask_channels.append(sample["masks"].get(name, np.zeros((self.size, self.size))))
                
            # Background is where no line is present
            bg = 1.0 - np.clip(sum(mask_channels), 0, 1)
            mask_channels.append(bg)
            
            stacked_masks = np.stack(mask_channels, axis=-1)
            
            images.append(img)
            masks.append(stacked_masks)
            
        return np.array(images, dtype=np.float32), np.array(masks, dtype=np.float32)

def train_and_export():
    setup_gpu_memory()
    
    # --- FULL SPECTRUM PARAMETERS ---
    TRAIN_SIZE = 224 
    BATCH_SIZE = 2 # Reduced for 224x224 stability
    NUM_SAMPLES = 1000 # Starting with 1000 for verification of the complex model
    EPOCHS = 10
    NUM_CLASSES = 16
    
    print(f"Initializing Full-Spectrum Training (Samples: {NUM_SAMPLES}, Classes: {NUM_CLASSES})...")
    train_gen = PalmDataGenerator(num_samples=NUM_SAMPLES, batch_size=BATCH_SIZE, size=TRAIN_SIZE)
    
    print("Building Full-Spectrum Attention U-Net + ASPP...")
    model = build_attention_unet_aspp(input_shape=(TRAIN_SIZE, TRAIN_SIZE, 3), num_classes=NUM_CLASSES)
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-4), 
        loss=dice_loss, 
        metrics=["accuracy"]
    )
    
    print("Starting training...")
    try:
        model.fit(train_gen, epochs=EPOCHS)
    except Exception as e:
        print(f"\n[CRITICAL ERROR during training]: {e}")
        return

    print("\nExporting Full-Spectrum model to TFLite...")
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        tflite_model = converter.convert()
        
        assets_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "app", "android", "app", "src", "main", "assets")
        os.makedirs(assets_dir, exist_ok=True)
        
        tflite_path = os.path.join(assets_dir, "palm_segmentation_full.tflite")
        with open(tflite_path, "wb") as f:
            f.write(tflite_model)
        print(f"Successfully exported full-spectrum model to {tflite_path}")
    except Exception as e:
        print(f"\n[CRITICAL ERROR during export]: {e}")

if __name__ == "__main__":
    train_and_export()
