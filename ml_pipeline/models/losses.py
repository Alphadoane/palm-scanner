import tensorflow as tf
import numpy as np

# --- DICE LOSS ---
def dice_loss(y_true, y_pred, smooth=1e-6):
    y_true_f = tf.reshape(y_true, [-1])
    y_pred_f = tf.reshape(y_pred, [-1])
    intersection = tf.reduce_sum(y_true_f * y_pred_f)
    score = (2. * intersection + smooth) / (tf.reduce_sum(y_true_f) + tf.reduce_sum(y_pred_f) + smooth)
    return 1. - score

# --- BOUNDARY LOSS ---
def get_edges(y_true):
    pool = tf.nn.max_pool2d(y_true, ksize=3, strides=1, padding='SAME')
    erosion = -tf.nn.max_pool2d(-y_true, ksize=3, strides=1, padding='SAME')
    edges = pool - erosion
    return edges

def approximate_distance_map(edges):
    return tf.nn.avg_pool2d(edges, ksize=5, strides=1, padding='SAME')

def boundary_loss(y_true, y_pred):
    edges_true = get_edges(y_true)
    dist_map = approximate_distance_map(edges_true)
    loss = tf.reduce_mean(tf.abs(y_pred - edges_true) * dist_map)
    return loss

# --- SDM LOSS ---
def sdm_loss(y_true_sdm, y_pred):
    y_pred_sdm = (y_pred - 0.5) * 2.0
    loss = tf.reduce_mean(tf.square(y_pred_sdm - y_true_sdm))
    return loss

# --- SKELETON-AWARE LOSS ---
def soft_erode(img):
    p1 = tf.nn.max_pool2d(-img, ksize=3, strides=1, padding='SAME')
    return -p1

def soft_dilate(img):
    return tf.nn.max_pool2d(img, ksize=3, strides=1, padding='SAME')

def soft_skeleton(img, iterations=10):
    skel = tf.zeros_like(img)
    for i in range(iterations):
        eroded = soft_erode(img)
        opened = soft_dilate(eroded)
        delta = tf.nn.relu(img - opened)
        skel += tf.nn.relu(delta)
        img = eroded
    return skel

def skeleton_loss(y_true, y_pred):
    sk_true = soft_skeleton(y_true)
    sk_pred = soft_skeleton(y_pred)
    return tf.reduce_mean(tf.abs(sk_true - sk_pred))

def topology_loss(y_true, y_pred):
    sk_true = soft_skeleton(y_true)
    sk_pred = soft_skeleton(y_pred)
    diff = tf.square(sk_true - sk_pred)
    weight = tf.stop_gradient(sk_true + sk_pred)
    return tf.reduce_mean(diff * weight)

def detect_junctions(skel):
    kernel = tf.ones((3,3,1,1))
    neighbors = tf.nn.conv2d(skel, kernel, strides=1, padding='SAME')
    return tf.nn.relu(neighbors - 2.0)

def junction_loss(y_true, y_pred):
    j_true = detect_junctions(soft_skeleton(y_true))
    j_pred = detect_junctions(soft_skeleton(y_pred))
    return tf.reduce_mean(tf.abs(j_true - j_pred))

def full_skeleton_loss(y_true, y_pred):
    bce = tf.keras.losses.BinaryCrossentropy()(y_true, y_pred)
    sk_loss = skeleton_loss(y_true, y_pred)
    topo_loss = topology_loss(y_true, y_pred)
    junc_loss = junction_loss(y_true, y_pred)
    return bce + 0.5 * sk_loss + 0.5 * topo_loss + 0.3 * junc_loss
