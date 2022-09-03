import gleam/os_mon
import gleam/os_mon/cpu
import gleam/os_mon/disk
import gleam/os_mon/mem
import gleam/io

pub fn main() {
  assert Ok(_) = os_mon.start()

  #("avg1", cpu.average_1())
  |> io.debug

  #("memory (GiB)", mem.get_system_memory_data().total / 1024 / 1024 / 1024)
  |> io.debug

  #("disk", disk.get_disk_data())
  |> io.debug
}
