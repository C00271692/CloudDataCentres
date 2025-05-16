import pandas as pd, matplotlib.pyplot as plt, re

df = pd.read_csv("results.csv", header=None, names=["metric","val"])

# -- Latency plot (cold vs warm) -----------------------------------
lat = df[df.metric.str.contains("_ms")]
lat["val"] = lat.val.astype(float)
lat.plot(kind="bar", x="metric", y="val", legend=False)
plt.ylabel("Latency (s)")
plt.title("Cold vs. Warm Latency – phi3, laptop CPU")
plt.tight_layout()
plt.savefig("latency_cold_warm.pdf")

# -- Throughput plot ------------------------------------------------
thr = df[df.metric.str.contains("^thr_c")]
thr["c"] = thr.metric.str.extract(r'c([0-9]+)').astype(int)
thr["val"] = thr.val.astype(float)
thr.sort_values("c").plot(x="c", y="val", marker="o")
plt.xlabel("Concurrent clients")
plt.ylabel("Requests / sec")
plt.title("Throughput vs. Concurrency – phi3")
plt.tight_layout()
plt.savefig("throughput_vs_c.pdf")

