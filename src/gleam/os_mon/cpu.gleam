//// A CPU Load and CPU Utilization Supervisor Process
////
//// Description
//// 
//// `cpu_sup` is a process which supervises the CPU load and CPU utilization.
//// It is part of the OS_Mon application, see `os_mon(6)`. Available for Unix,
//// although CPU utilization values `util` are only available for Solaris,
//// Linux and FreeBSD.
//// 
//// The load values are proportional to how long time a runnable Unix process
//// has to spend in the run queue before it is scheduled. Accordingly, higher
//// values mean more system load. The returned value divided by 256 produces
//// the figure displayed by `rup` and `top`. What is displayed as 2.00 in
//// `rup`, is displayed as load up to the second mark in xload.
//// 
//// For example, `rup` displays a load of 128 as 0.50, and 512 as 2.00.
//// 
//// If the user wants to view load values as percentage of machine capacity,
//// then this way of measuring presents a problem, because the load values are
//// not restricted to a fixed interval. In this case, the following simple
//// mathematical transformation can produce the load value as a percentage:
//// 
////       Percent_load = 100 * (1 - d / (d + load))
//// 
//// `d` determines which load value should be associated with which
//// percentage.
//// Choosing `d` = 50 means that 128 is 60% load, 256 is 80%, 512 is 90%, and
//// so on.
//// 
//// Another way of measuring system load is to divide the number of busy CPU
//// cycles by the total number of CPU cycles. This produces values in the
//// 0-100 range immediately. However, this method hides the fact that a
//// machine can be more or less saturated. CPU utilization is therefore a
//// better name than system load for this measure.
//// 
//// A server which receives just enough requests to never become idle will
//// score a CPU utilization of 100%. If the server receives 50% more requests,
//// it will still score 100%. When the system load is calculated with the
//// percentage formula shown previously, the load will increase from 80% to
//// 87%.
//// 
//// The avg1/0, avg5/0, and avg15/0 functions can be used for retrieving
//// system load values, and the `util` function can be used for retrieving CPU
//// utilization values.
//// 
//// When run on Linux, `cpu_sup` assumes that the `/proc` file system is
//// present and accessible by `cpu_sup`. If it is not, `cpu_sup` will
//// terminate.

import gleam/map
import gleam/erlang/atom.{Atom}
import gleam/result.{unwrap}
import gleam/list

/// Returns the average system load in the last minute, as described above. 0
/// represents no load, 256 represents the load reported as 1.00 by rup.
///
/// Returns 0 if `cpu_sup` is not available.
pub external fn average_1() -> Int =
  "cpu_sup" "avg1"

/// Returns the average system load in the last minute, as described above. 0
/// represents no load, 256 represents the load reported as 1.00 by rup.
///
/// Returns 0 if `cpu_sup` is not available.
pub external fn average_5() -> Int =
  "cpu_sup" "avg5"

/// Returns the average system load in the last fifteen minutes, as described
/// above. 0 represents no load, 256 represents the load reported as 1.00 by
/// rup.
///
/// Returns 0 if `cpu_sup` is not available.
pub external fn average_15() -> Int =
  "cpu_sup" "avg15"

/// Returns the number of UNIX processes running on this machine. This is a
/// crude way of measuring the system load, but it may be of interest in some
/// cases.
///
/// Returns 0 if `cpu_sup` is not available.
pub external fn nprocs() -> Int =
  "cpu_sup" "nprocs"

/// Returns CPU utilization since the last call to `average` by the calling
/// process.
///
/// Note:
/// The returned value of the first call to `average` by a process will on most
/// systems be the CPU utilization since system boot, but this is not
/// guaranteed and the value should therefore be regarded as garbage. This also
/// applies to the first call after a restart of `cpu_sup`.
///
/// The CPU utilization is defined as the sum of the percentage shares of the
/// CPU cycles spent in all busy processor states in average on all CPUs.
///
/// Returns 0 if `cpu_sup` is not available.
pub external fn average() -> Float =
  "cpu_sup" "util"

type UtilizationOption {
  /// The returned UtilDesc(s) will be even more detailed.
  Detailed
  /// Each CPU will be specified separately (assuming this information can be
  /// retrieved from the operating system), that is, a list with one UtilDesc
  /// per CPU will be returned.
  PerCpu
}

external fn ffi_utilization_detailed_per_cpu(
  List(UtilizationOption),
) -> List(#(Int, List(#(Key, Float)), List(#(Key, Float)), List(Nil))) =
  "cpu_sup" "util"

/// Statitics about CPU usage
pub type CpuUtilization {
  CpuUtilization(
    soft_irq: Float,
    hard_irq: Float,
    kernel: Float,
    nice_user: Float,
    user: Float,
    steal: Float,
    idle: Float,
    wait: Float,
  )
}

pub type CpuUtilizationDetailed {
  CpuUtilizationDetailed(ids: List(Int), details: CpuUtilization)
}

/// Atoms used for map lookups
type Key {
  SoftIrq
  HardIrq
  Kernel
  NiceUser
  User
  Steal
  Idle
  Wait
}

/// Returns CPU utilization since the last call to `utilization` by the calling
/// process.
///
/// Note:
/// The returned value of the first call to `utilization` by a process will on
/// most systems be the CPU utilization since system boot, but this is not
/// guaranteed and the value should therefore be regarded as garbage. This also
/// applies to the first call after a restart of `cpu_sup`.
///
/// Throws an exception if `cpu_sup` is not available.
pub fn utilization_detailed_per_cpu() -> List(CpuUtilization) {
  ffi_utilization_detailed_per_cpu([Detailed, PerCpu])
  |> list.map(fn(cpu) {
    assert #(_, line1, line2, _) = cpu
    let m = map.merge(map.from_list(line1), map.from_list(line2))
    CpuUtilization(
      soft_irq: get(m, SoftIrq),
      hard_irq: get(m, HardIrq),
      kernel: get(m, Kernel),
      nice_user: get(m, NiceUser),
      user: get(m, User),
      steal: get(m, Steal),
      idle: get(m, Idle),
      wait: get(m, Wait),
    )
  })
}

fn get(m, k) {
  unwrap(map.get(m, k), 0.0)
}

external fn ffi_utilization_detailed(
  List(UtilizationOption),
) -> #(List(Int), List(#(Key, Float)), List(#(Key, Float)), List(Nil)) =
  "cpu_sup" "util"

pub fn utilization_detailed() -> CpuUtilizationDetailed {
  assert #(ids, line1, line2, _) = ffi_utilization_detailed([Detailed])
  let m = map.merge(map.from_list(line1), map.from_list(line2))
  CpuUtilizationDetailed(
    ids: ids,
    details: CpuUtilization(
      soft_irq: get(m, SoftIrq),
      hard_irq: get(m, HardIrq),
      kernel: get(m, Kernel),
      nice_user: get(m, NiceUser),
      user: get(m, User),
      steal: get(m, Steal),
      idle: get(m, Idle),
      wait: get(m, Wait),
    ),
  )
}

pub type CpuUtilizationTotal {
  CpuUtilizationTotal(active: Float, idle: Float)
}

external fn ffi_utilization_per_cpu(
  List(UtilizationOption),
) -> List(#(Int, Float, Float, List(Nil))) =
  "cpu_sup" "util"

pub fn utilization_per_cpu() {
  list.map(
    ffi_utilization_per_cpu([PerCpu]),
    fn(entry) {
      assert #(_, active, idle, _) = entry
      CpuUtilizationTotal(active: active, idle: idle)
    },
  )
}

external fn ffi_utilization(
  List(UtilizationOption),
) -> #(Atom, Float, Float, List(Nil)) =
  "cpu_sup" "util"

pub fn utilization() {
  assert #(_, active, idle, _) = ffi_utilization([])
  CpuUtilizationTotal(active: active, idle: idle)
}
