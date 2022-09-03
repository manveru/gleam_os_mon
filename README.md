# gleam_os_mon

[![Package Version](https://img.shields.io/hexpm/v/gleam_os_mon)](https://hex.pm/packages/gleam_os_mon)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleam_os_mon/)

A rather minimal wrapper around the functions found in
[os_mon](https://www.erlang.org/doc/apps/os_mon/index.html).

It probably goes without saying, but this functionality is only available when
runnning on BEAM.

## Quick start

```gleam
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
```

This will output something like:

```
#("avg1", 79)
#("memory (GB)", 125)
#("disk", //erl(#{
  "/" => {disk,"/",520187392,68},
  "/big" => {disk,"/big",20214949760,44},
  "/boot" => {disk,"/boot",522984,38},
  "/dev" => {disk,"/dev",6591368,0},
  "/dev/shm" => {disk,"/dev/shm",65913676,3},
  "/home" => {disk,"/home",405588736,59},
  "/mnt" => {disk,"/mnt",166689536,1},
  "/run" => {disk,"/run",32956840,1},
  "/run/user/1000" => {disk,"/run/user/1000",13182732,1},
  "/run/wrappers" => {disk,"/run/wrappers",65913672,1}}))
```

## Installation

This package can be added to your Gleam project:

```sh
gleam add gleam_os_mon
```

## Development

```sh
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## TODO

Most basic things are implemented, but `os_sup` and `nteventlog` are more
Windows specific, so I'm not going to work on them myself. PRs are welcome
though.

- [x] os_mon (App)
- [x] cpu_sup
  - [x] avg1/0
  - [x] avg15/0
  - [x] avg5/0
  - [x] nprocs/0
  - [x] util/0
  - [x] util/1
- [x] disksup
  - [x] get_almost_full_threshold/0
  - [x] get_check_interval/0
  - [x] get_disk_data/0
  - [x] set_almost_full_threshold/1
  - [x] set_check_interval/1
- [x] memsup
  - [x] get_check_interval/0
  - [x] get_helper_timeout/0
  - [x] get_memory_data/0
  - [x] get_os_wordsize/0
  - [x] get_procmem_high_watermark/0
  - [x] get_sysmem_high_watermark/0
  - [x] get_system_memory_data/0
  - [x] set_check_interval/1
  - [x] set_helper_timeout/1
  - [x] set_procmem_high_watermark/1
  - [x] set_sysmem_high_watermark/1
- [ ] os_sup
  - [ ] disable/0
  - [ ] disable/2
  - [ ] enable/0
  - [ ] enable/2
- [ ] nteventlog
  - [ ] start/2
  - [ ] start_link/2
  - [ ] stop/0
