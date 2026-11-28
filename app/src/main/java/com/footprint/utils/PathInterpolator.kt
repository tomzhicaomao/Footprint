package com.footprint.utils

import com.amap.api.maps.model.LatLng
import kotlin.math.sqrt

object PathInterpolator {
    /**
     * Smooths a GPS polyline without Catmull-Rom overshoot on sharp turns or uneven point spacing.
     * Uses corner-cutting (Chaikin-style) only on gentle bends and preserves sharp corners & long gaps.
     */
    fun interpolate(points: List<LatLng>, multiplier: Int = 4): List<LatLng> {
        if (points.size < 3 || multiplier <= 1) return points

        val result = ArrayList<LatLng>(points.size * 2)
        result.add(points.first())

        for (i in 1 until points.size - 1) {
            val prev = points[i - 1]
            val curr = points[i]
            val next = points[i + 1]

            val v1Lat = curr.latitude - prev.latitude
            val v1Lng = curr.longitude - prev.longitude
            val v2Lat = next.latitude - curr.latitude
            val v2Lng = next.longitude - curr.longitude

            val len1 = sqrt(v1Lat * v1Lat + v1Lng * v1Lng)
            val len2 = sqrt(v2Lat * v2Lat + v2Lng * v2Lng)

            if (len1 < 1e-8 || len2 < 1e-8) {
                result.add(curr)
                continue
            }

            // Skip smoothing across large gaps (~>80m) or sharp turns (>60 deg) to prevent corner overshoot
            val cosTheta = (v1Lat * v2Lat + v1Lng * v2Lng) / (len1 * len2)
            val isLargeGap = len1 > 0.0008 || len2 > 0.0008
            if (isLargeGap || cosTheta < 0.5) {
                result.add(curr)
            } else {
                // Gentle Chaikin corner bevel (0.22 / 0.78) stays strictly inside the convex hull
                result.add(
                    LatLng(
                        prev.latitude * 0.22 + curr.latitude * 0.78,
                        prev.longitude * 0.22 + curr.longitude * 0.78
                    )
                )
                result.add(
                    LatLng(
                        curr.latitude * 0.78 + next.latitude * 0.22,
                        curr.longitude * 0.78 + next.longitude * 0.22
                    )
                )
            }
        }

        result.add(points.last())
        return result
    }
}
