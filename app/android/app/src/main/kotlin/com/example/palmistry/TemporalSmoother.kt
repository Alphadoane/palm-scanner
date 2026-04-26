package com.example.palmistry

import android.graphics.PointF

class TemporalSmoother(val alpha: Float = 0.7f) {
    private var prevPoints: Map<String, PointF>? = null

    fun smooth(current: Map<String, PointF>): Map<String, PointF> {
        if (prevPoints == null) {
            prevPoints = current
            return current
        }
        val smoothed = mutableMapOf<String, PointF>()
        for (key in current.keys) {
            val prev = prevPoints!![key]
            val curr = current[key]!!
            if (prev != null) {
                smoothed[key] = PointF(
                    alpha * prev.x + (1 - alpha) * curr.x,
                    alpha * prev.y + (1 - alpha) * curr.y
                )
            } else {
                smoothed[key] = curr
            }
        }
        prevPoints = smoothed
        return smoothed
    }
}
