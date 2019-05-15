
import asyncio
from task_bench_direct import (app_create, app_task_graphs, time,
    execute_task_graph, sys)
from dask.distributed import wait, Client


async def execute_task_bench():
    from task_bench_core import ffi, c

    app = app_create(sys.argv)
    task_graphs = app_task_graphs(app)
    start_time = time.perf_counter()
    computations = {}
    next_tid = 0
    results = []
    async with Client(processes=False, asynchronous=True) as client:
        for task_graph in task_graphs:
            result, next_tid = execute_task_graph(task_graph, computations, next_tid)
            results.extend(result)
            futures = client.get(computations, results, sync=False)
            await wait(futures)
        total_time = time.perf_counter() - start_time
        c.app_report_timing(app, total_time)

        1 + 1


if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(execute_task_bench())
    # execute_task_bench()
