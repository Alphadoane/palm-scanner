import tensorflow as tf

def ds_conv_block(x, filters, stride=1):
    x = tf.keras.layers.DepthwiseConv2D(3, strides=stride, padding='same')(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.ReLU()(x)
    x = tf.keras.layers.Conv2D(filters, 1, padding='same')(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.ReLU()(x)
    return x

def attention_gate(x, g, filters):
    theta_x = tf.keras.layers.Conv2D(filters, 1)(x)
    phi_g = tf.keras.layers.Conv2D(filters, 1)(g)
    add = tf.keras.layers.Add()([theta_x, phi_g])
    act = tf.keras.layers.ReLU()(add)
    psi = tf.keras.layers.Conv2D(1, 1, activation='sigmoid')(act)
    return tf.keras.layers.Multiply()([x, psi])

def aspp(x, filters=256):
    shape = tf.keras.backend.int_shape(x)
    conv1 = tf.keras.layers.Conv2D(filters, 1, padding='same', activation='relu')(x)
    conv2 = tf.keras.layers.Conv2D(filters, 3, dilation_rate=2, padding='same', activation='relu')(x)
    conv3 = tf.keras.layers.Conv2D(filters, 3, dilation_rate=4, padding='same', activation='relu')(x)
    conv4 = tf.keras.layers.Conv2D(filters, 3, dilation_rate=6, padding='same', activation='relu')(x)
    pool = tf.keras.layers.GlobalAveragePooling2D()(x)
    pool = tf.keras.layers.Reshape((1, 1, shape[-1]))(pool)
    pool = tf.keras.layers.Conv2D(filters, 1, padding='same', activation='relu')(pool)
    pool = tf.keras.layers.UpSampling2D(size=(shape[1], shape[2]), interpolation='bilinear')(pool)
    x = tf.keras.layers.Concatenate()([conv1, conv2, conv3, conv4, pool])
    x = tf.keras.layers.Conv2D(filters, 1, padding='same', activation='relu')(x)
    return x

def encoder(inputs):
    skips = []
    x = ds_conv_block(inputs, 32)
    skips.append(x)
    x = ds_conv_block(x, 64, stride=2)
    skips.append(x)
    x = ds_conv_block(x, 128, stride=2)
    skips.append(x)
    x = ds_conv_block(x, 256, stride=2)
    skips.append(x)
    x = ds_conv_block(x, 512, stride=2)
    return x, skips

def decoder(x, skips):
    filters = [256, 128, 64, 32]
    for i in range(4):
        x = tf.keras.layers.UpSampling2D((2, 2))(x)
        skip = skips[-(i + 1)]
        skip = attention_gate(skip, x, filters[i])
        x = tf.keras.layers.Concatenate()([x, skip])
        x = ds_conv_block(x, filters[i])
    return x

def build_attention_unet_aspp(input_shape=(224, 224, 3), num_classes=16):
    inputs = tf.keras.layers.Input(shape=input_shape)
    # Encoder
    x, skips = encoder(inputs)
    # ASPP Bottleneck
    x = aspp(x, filters=256)
    # Decoder with Attention
    x = decoder(x, skips)
    # Output Layer
    outputs = tf.keras.layers.Conv2D(num_classes, 1, activation='sigmoid')(x)
    return tf.keras.Model(inputs, outputs)

if __name__ == "__main__":
    model = build_attention_unet_aspp()
    model.summary()
