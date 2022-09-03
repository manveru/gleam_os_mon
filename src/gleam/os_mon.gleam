import gleam/erlang
import gleam/erlang/atom

// Start the os_mon application, this is required before calling any of the sub
// applications.
pub fn start() {
  erlang.ensure_all_started(atom.create_from_string("os_mon"))
}
