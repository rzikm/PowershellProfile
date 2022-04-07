function DecodeTaskStateFlags([int]$Flags) {
    # values taken from https://source.dot.net/#System.Private.CoreLib/Task.cs,142

    $flagValues = @{
        Started                    = 0x10000
        DelegateInvoked            = 0x20000
        Disposed                   = 0x40000
        ExceptionObservedByParent  = 0x80000
        CancellationAcknowledged   = 0x100000
        Faulted                    = 0x200000
        Canceled                   = 0x400000
        WaitingOnChildren          = 0x800000
        RanToCompletion            = 0x1000000
        WaitingForActivation       = 0x2000000
        CompletionReserved         = 0x4000000
        WaitCompletionNotification = 0x10000000
        ExecutionContextIsNull     = 0x20000000
        TaskScheduledWasFired      = 0x40000000
    }

    $res = @()

    foreach ($kvp in $flagValues.GetEnumerator()) {
        if (($Flags -band $kvp.Value) -ne 0) {
            $res += $kvp.Key
        }
    }

    return $res
}