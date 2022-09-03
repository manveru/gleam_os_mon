import gleam/map.{Map}
import gleam/list
import gleam/int
import gleam/dynamic.{Dynamic}
import gleam/erlang.{rescue}

pub type Errors {
  ValueTooSmall(Int)
  ValueTooLarge(Int)
  Crash(erlang.Crash)
}

external fn ffi_set_almost_full_threshold(Float) -> Result(Nil, Nil) =
  "disksup" "set_almost_full_threshold"

// Changes the threshold, given as a float, for disk space utilization.
// The change will take effect during the next disk space check and is
// non-persist. That is, in case of a process restart, this value is forgotten
// and the default value will be used. See Configuration above.
pub fn set_almost_full_threshold(percent: Int) -> Result(Int, Errors) {
  case percent {
    _ if percent < 0 -> Error(ValueTooSmall(percent))
    _ if percent > 100 -> Error(ValueTooLarge(percent))
    _ ->
      case
        rescue(fn() {
          ffi_set_almost_full_threshold(int.to_float(percent) /. 100.0)
        })
      {
        Ok(_) -> Ok(percent)
        Error(err) -> Error(Crash(err))
      }
  }
}

// Returns the threshold, in percent, for disk space utilization.
pub external fn get_almost_full_threshold() -> Int =
  "disksup" "get_almost_full_threshold"

external fn ffi_get_check_interval() -> Int =
  "disksup" "get_check_interval"

// Returns the time interval, in minutes, for the periodic disk space check.
pub fn get_check_interval() -> Int {
  ffi_get_check_interval() / 60000
}

external fn ffi_set_check_interval(Int) -> Dynamic =
  "disksup" "set_check_interval"

// Changes the time interval, given in minutes, for the periodic disk space check.
//
// The change will take effect after the next disk space check and is
// non-persist. That is, in case of a process restart, this value is forgotten
// and the default value will be used.
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

external fn disksup_get_disk_data() -> List(#(String, Int, Int)) =
  "disksup" "get_disk_data"

pub type Disk {
  Disk(
    // Identifies the disk or partition.
    id: String,
    // The total size of the disk or partition in kbytes
    size: Int,
    // The percentage of disk space used
    capacity: Int,
  )
}

// The result of the latest disk check.
pub fn get_disk_data() -> Map(String, Disk) {
  list.fold(
    disksup_get_disk_data(),
    map.new(),
    fn(sum, entry) {
      assert #(id, kbyte, capacity) = entry
      map.insert(sum, id, Disk(id, kbyte, capacity))
    },
  )
}
