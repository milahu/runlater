# runlater

tool for dynamic task scheduling.

when the user is active or the cpu load is high, then dont run any jobs.  
when the user is away and the cpu load is low, then run one job at a time.  
when a job is running and the user returns, pause the job.

this is useful for long-running cpu-heavy jobs like ffmpeg.
