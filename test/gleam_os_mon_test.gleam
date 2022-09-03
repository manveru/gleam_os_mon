import gleam/list
import gleam/map
import gleam/os_mon
import gleam/os_mon/cpu
import gleam/os_mon/disk
import gleam/os_mon/mem
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn disk_test() {
  should.be_ok(os_mon.start())

  disk.set_almost_full_threshold(190)
  |> should.be_error

  disk.get_almost_full_threshold()
  |> should.equal(80)

  disk.set_almost_full_threshold(90)
  |> should.be_ok

  disk.get_almost_full_threshold()
  |> should.equal(90)

  disk.set_check_interval(-1)
  |> should.be_error

  disk.get_check_interval()
  |> should.equal(30)

  disk.set_check_interval(1)
  |> should.equal(Ok(1))

  disk.get_check_interval()
  |> should.equal(1)

  {
    disk.get_disk_data()
    |> map.size > 0
  }
  |> should.be_true
}

pub fn cpu_utilization_average_test() {
  should.be_ok(os_mon.start())

  { cpu.average_1() > 0 }
  |> should.be_true

  { cpu.average_5() > 0 }
  |> should.be_true

  { cpu.average_15() > 0 }
  |> should.be_true

  { cpu.nprocs() > 0 }
  |> should.be_true

  { cpu.average() >. 0.0 }
  |> should.be_true
}

pub fn cpu_average_test() {
  should.be_ok(os_mon.start())

  { cpu.average() >. 0.0 }
  |> should.be_true
}

pub fn cpu_utilization_test() {
  should.be_ok(os_mon.start())

  assert cpu.CpuUtilizationTotal(total, idle) = cpu.utilization()

  { idle >. 0.0 }
  |> should.be_true

  { total >. 0.0 }
  |> should.be_true
}

pub fn cpu_utilization_per_cpu_test() {
  should.be_ok(os_mon.start())

  assert [cpu.CpuUtilizationTotal(total, idle), ..] = cpu.utilization_per_cpu()

  { idle >=. 0.0 }
  |> should.be_true

  { total >=. 0.0 }
  |> should.be_true
}

pub fn cpu_utilization_detailed_test() {
  should.be_ok(os_mon.start())

  assert cpu.CpuUtilizationDetailed(ids, detail) = cpu.utilization_detailed()

  { list.length(ids) > 0 }
  |> should.be_true

  list.first(ids)
  |> should.equal(Ok(0))

  { detail.idle >=. 0.0 }
  |> should.be_true
}

pub fn cpu_utilization_detailed_per_cpu_test() {
  should.be_ok(os_mon.start())

  assert [first, ..] = cpu.utilization_detailed_per_cpu()

  { first.soft_irq >=. 0.0 }
  |> should.be_true
}

pub fn mem_get_check_interval_test() {
  should.be_ok(os_mon.start())

  mem.get_check_interval()
  |> should.equal(1)
}

pub fn mem_get_helper_timeout_test() {
  should.be_ok(os_mon.start())

  mem.get_helper_timeout()
  |> should.equal(30)
}

pub fn mem_get_memory_data_test() {
  should.be_ok(os_mon.start())

  let data = mem.get_memory_data()

  { data.total > 0 }
  |> should.be_true

  { data.allocated > 0 }
  |> should.be_true

  { data.worst.1 > 0 }
  |> should.be_true
}

pub fn mem_get_os_wordsize_test() {
  should.be_ok(os_mon.start())

  mem.get_os_wordsize()
  |> should.equal(64)
}

pub fn mem_set_procmem_high_watermark_test() {
  should.be_ok(os_mon.start())

  mem.get_procmem_high_watermark()
  |> should.equal(5)

  mem.set_procmem_high_watermark(5)
  |> should.be_ok

  mem.get_procmem_high_watermark()
  |> should.equal(5)
}

pub fn mem_get_procmem_high_watermark_test() {
  should.be_ok(os_mon.start())

  mem.get_procmem_high_watermark()
  |> should.equal(5)
}

pub fn mem_get_sysmem_high_watermark_test() {
  should.be_ok(os_mon.start())

  mem.get_sysmem_high_watermark()
  |> should.equal(80)
}

pub fn mem_set_helper_timeout_test() {
  should.be_ok(os_mon.start())

  mem.set_helper_timeout(2)
  |> should.be_ok
}

pub fn mem_get_system_memory_data_test() {
  should.be_ok(os_mon.start())

  let m = mem.get_system_memory_data()

  { m.available > 0 }
  |> should.be_true
}
