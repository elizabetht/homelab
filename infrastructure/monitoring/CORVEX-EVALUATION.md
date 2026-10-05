# Corvex evaluation and Prometheus recovery

The 2026-10-05 inspection found production Prometheus in an OOM restart loop.
OOM means the process exceeded its memory limit.
The previous container exited with code 137 during WAL recovery.
WAL means write-ahead log.
The old limit was 1 GiB.

The live Prometheus resource now requests 2 GiB and permits 4 GiB.
The CPU request is 500 millicores.
`prometheus/values.yaml` contains the same resource settings.
The replacement pod became ready with zero restarts during the recorded observation.
The existing deployment uses temporary local storage.
This repair does not convert production storage into persistent storage.
Replacing the pod can lose that temporary history.
The bounded storage test uses a separate persistent volume.

The companion token-labs repository contains the evaluation source:
`deploy/platform/corvex` and `scripts/corvex`.
Its evidence directory is `results/2026-10-05-corvex`.
The evaluation uses a 2 GiB Longhorn volume on Spark-02.
The controller had spare memory but was not a ready Longhorn storage node.
No production inference template or Service selector changed.
The Qwen repair removed only a terminal Failed worker pod.
The existing controller recreated the worker with the same specification.
The pending frontend then scheduled successfully.

If memory pressure requires rollback, first inspect current memory use.
Restore the prior Prometheus resource values only if they can support recovery.
The previous 1 GiB limit caused the observed failure.
A blind rollback would likely restore that failure.
The pre-change resource specification is preserved in token-labs evidence.
Do not roll back Qwen by deliberately recreating its terminal failed state.
If Qwen regresses, preserve logs and follow the model rollout runbook.

The evidence does not demonstrate production retention or 99.9% availability.
The DCGM profiling module remained unavailable.
No host driver upgrade formed part of this work.
