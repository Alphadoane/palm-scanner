import numpy as np
from scipy.stats import rankdata

class FeatureCalibrator:
    def __init__(self, dataset_stats=None):
        self.dataset_stats = dataset_stats or {}

    def normalize_length(self, value, reference):
        return value / reference if reference > 0 else 0

    def normalize_depth(self, values):
        p10 = np.percentile(values, 10)
        p90 = np.percentile(values, 90)
        return np.clip((values - p10) / (p90 - p10 + 1e-6), 0, 1)

    def percentile(self, value, distribution):
        return rankdata(np.append(distribution, value))[-1] / (len(distribution) + 1)

    def categorize(self, pct):
        if pct < 0.2: return "very_short"
        elif pct < 0.4: return "short"
        elif pct < 0.7: return "medium"
        elif pct < 0.9: return "long"
        return "very_long"

    def line_strength(self, depth, continuity, contrast):
        return 0.5 * depth + 0.3 * continuity + 0.2 * contrast

    def confidence(self, quality_metrics):
        weights = {"lighting": 0.4, "blur": 0.3, "edge_strength": 0.3}
        return sum(quality_metrics[k] * weights[k] for k in weights)

    def calibrate(self, raw_features, distributions):
        output = {}
        length_norm = self.normalize_length(
            raw_features.get("life_line_length", 0),
            raw_features.get("palm_height", 1)
        )
        length_pct = self.percentile(
            length_norm,
            distributions.get("life_line_length", [0])
        )
        output["life_line"] = {
            "length_norm": float(length_norm),
            "length_pct": float(length_pct),
            "category": self.categorize(length_pct),
            "confidence": self.confidence(raw_features.get("quality", {"lighting": 1, "blur": 1, "edge_strength": 1}))
        }
        return output

if __name__ == "__main__":
    calibrator = FeatureCalibrator()
    raw_features = {
        "life_line_length": 210,
        "palm_height": 300,
        "quality": {"lighting": 0.8, "blur": 0.9, "edge_strength": 0.85}
    }
    distributions = {
        "life_line_length": np.random.rand(1000)
    }
    result = calibrator.calibrate(raw_features, distributions)
    print("Calibrated features:", result)
