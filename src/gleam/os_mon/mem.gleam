import gleam/erlang/process.{Pid}
import gleam/int
import gleam/map
import gleam/result
import gleam/erlang.{rescue}

pub type Errors {
  ValueTooSmall(Int)
  ValueTooLarge(Int)
  Crash(erlang.Crash)
}

/// Returns the timeout value, in seconds, for memory checks.
pub external fn get_helper_timeout() -> Int =
  "memsup" "get_helper_timeout"

external fn ffi_set_helper_timeout(Int) -> Int =
  "memsup" "set_helper_timeout"

/// Changes the timeout value, given in seconds, for memory checks.
/// 
/// The change will take effect for the next memory check and is
/// non-persistent. That is, in the case of a process restart, this value is
/// forgotten and the default value will be used.
pub fn set_helper_timeout(seconds: Int) -> Result(Int, Errors) {
  case seconds {
    _ if seconds < 1 -> Error(ValueTooSmall(seconds))
    _ ->
      case rescue(fn() { ffi_set_helper_timeout(seconds) }) {
        Ok(_) -> Ok(seconds)
        Error(err) -> Error(Crash(err))
      }
  }
}

pub type MemoryData {
  MemoryData(total: Int, allocated: Int, worst: #(Pid, Int))
}

external fn ffi_get_memory_data() -> #(Int, Int, #(Pid, Int)) =
  "memsup" "get_memory_data"

/// Returns the result of the latest memory check, where Total is the total
/// memory size and Allocated the allocated memory size, in bytes.
/// 
/// Worst is the pid and number of allocated bytes of the largest Erlang
/// process on the node. If `memsup` should not collect process data, that is
/// if the configuration parameter `memsup_system_only` was set to true, Worst
/// is undefined.
/// 
/// The function is normally asynchronous in the sense that it does not invoke
/// a memory check, but returns the latest available value. The one exception
/// if is the function is called before a first memory check is finished, in
/// which case it does not return a value until the memory check is finished.
/// 
/// Returns all zeroes or raises an exception if `memsup` is not available, or
/// if all memory checks so far have timed out.
pub fn get_memory_data() -> MemoryData {
  assert #(total, allocated, worst) = ffi_get_memory_data()
  MemoryData(total: total, allocated: allocated, worst: worst)
}

/// Returns the wordsize of the current running operating system.
/// Wordsize = 32 | 64 | unsupported_os
pub external fn get_os_wordsize() -> Int =
  "memsup" "get_os_wordsize"

external fn ffi_get_check_interval() -> Int =
  "memsup" "get_check_interval"

/// Returns the time interval for the periodic memory check in minutes.
pub fn get_check_interval() -> Int {
  ffi_get_check_interval() / 60000
}

/// Changes the time interval for the periodic memory check.
/// 
/// The change will take effect after the next memory check and is
/// non-persistent. That is, in case of a process restart, this value is
/// forgotten and the default value will be used.
external fn ffi_set_check_interval(Int) -> Int =
  "memsup" "set_check_interval"

pub fn set_check_interval(minutes: Int) -> Result(Int, Errors) {
  case minutes {
    _ if minutes <= 0 -> Error(ValueTooSmall(minutes))
    _ ->
      case rescue(fn() { ffi_set_check_interval(minutes) }) {
        Ok(_) -> Ok(minutes)
        Error(err) -> Error(Crash(err))
      }
  }
}

/// Returns the threshold, in percent, for process memory allocation.
pub external fn get_procmem_high_watermark() -> Int =
  "memsup" "get_procmem_high_watermark"

external fn ffi_set_procmem_high_watermark(Float) -> Result(Nil, Nil) =
  "memsup" "set_procmem_high_watermark"

/// Changes the threshold for process memory allocation.
/// 
/// The change will take effect during the next periodic memory check and is
/// non-persistent. That is, in case of a process restart, this value is
/// forgotten and the default value will be used.
pub fn set_procmem_high_watermark(percent: Int) -> Result(Int, Errors) {
  case percent {
    _ if percent < 0 -> Error(ValueTooSmall(percent))
    _ if percent > 100 -> Error(ValueTooLarge(percent))
    _ ->
      case
        rescue(fn() {
          ffi_set_procmem_high_watermark(int.to_float(percent) /. 100.0)
        })
      {
        Ok(_) -> Ok(percent)
        Error(err) -> Error(Crash(err))
      }
  }
}

/// Returns the threshold, in percent, for system memory allocation.
pub external fn get_sysmem_high_watermark() -> Int =
  "memsup" "get_sysmem_high_watermark"

external fn ffi_set_sysmem_high_watermark(Float) -> Int =
  "memsup" "set_sysmem_high_watermark"

/// Changes the threshold, in percent, for system memory allocation.
/// 
/// The change will take effect during the next periodic memory check and is
/// non-persistent. That is, in case of a process restart, this value is
/// forgotten and the default value will be used.
pub fn set_sysmem_high_watermark(percent: Int) -> Result(Int, Errors) {
  case percent {
    _ if percent < 0 -> Error(ValueTooSmall(percent))
    _ if percent > 100 -> Error(ValueTooLarge(percent))
    _ ->
      case
        rescue(fn() {
          ffi_set_sysmem_high_watermark(int.to_float(percent) /. 100.0)
        })
      {
        Ok(_) -> Ok(percent)
        Error(err) -> Error(Crash(err))
      }
  }
}

pub type Memory {
  /// All memory sizes are presented as number of bytes.
  Memory(
    /// Informs about the amount memory that is available for increased usage
    /// if there is an increased memory need. This value is not based on a
    /// calculation of the other provided values and should give a better value
    /// of the amount of memory that actually is available than calculating a
    /// value based on the other values reported.
    available: Int,
    /// The amount of memory the system uses for temporary storing raw disk
    /// blocks. 
    buffered: Int,
    /// The amount of memory the system uses for cached files read from disk.
    /// On Linux, also memory marked as reclaimable in the kernel slab
    /// allocator will be added to this value. 
    cached: Int,
    /// The amount of free memory available to the Erlang emulator for
    /// allocation.
    free: Int,
    /// The amount of memory the system has available for disk swap. 
    swap_free: Int,
    /// The amount of total amount of memory the system has available for disk
    /// swap. 
    swap_total: Int,
    // The amount of memory available to the whole operating system. This may
    // well be equal to total_memory but not necessarily.
    system_total: Int,
    /// The total amount of memory available to the Erlang emulator, allocated
    /// and free. May or may not be equal to the amount of memory configured in
    /// the system.
    total: Int,
  )
}

type MemKey {
  AvailableMemory
  BufferedMemory
  CachedMemory
  FreeMemory
  FreeSwap
  SystemTotalMemory
  TotalMemory
  TotalSwap
}

external fn ffi_get_system_memory_data() -> List(#(MemKey, Int)) =
  "memsup" "get_system_memory_data"

pub fn get_system_memory_data() -> Memory {
  let m = map.from_list(ffi_get_system_memory_data())
  Memory(
    available: get(m, AvailableMemory),
    buffered: get(m, BufferedMemory),
    cached: get(m, CachedMemory),
    free: get(m, FreeMemory),
    swap_free: get(m, FreeSwap),
    swap_total: get(m, TotalSwap),
    system_total: get(m, SystemTotalMemory),
    total: get(m, TotalMemory),
  )
}

fn get(m, k) {
  m
  |> map.get(k)
  |> result.unwrap(0)
}
