#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin.C
#elseif os(Linux) || os(Android) || os(FreeBSD)
import Glibc
#endif
/*
public func run(command: String, arguments: [String] = [], path: String? = nil, environment: [String: String] = [:], debug: Bool = false, closure: (String) throws -> Void = { _ in }) throws {
    let success = process(command: command, arguments: arguments, path: path, environment: environment, debug: debug, redirect: true) { string in
        do {
            try closure(string)
        } catch { }
    }
    guard success else { throw Fault.launch }
}
*/
func process(command: String, arguments: [String], path: String?, environment: [String: String], debug: Bool, redirect: Bool, closure: (String) -> Void) -> Bool {
    let space = arguments.count == 0 ? "" : " "
    let final = command + space + arguments.joined(separator: " ")
    let argument: String
    if let path {
        argument = "\ncd \(path) && \(final)"
    } else {
        argument = "\n\(final)"
    }
    let arguments = ["sh", debug ? "-xc" : "-c", argument]
    return process(arguments: arguments, environment: environment, redirect: redirect, closure)
}

private func process(arguments: [String], environment: [String: String], redirect: Bool, _ closure: (String) -> Void) -> Bool {
    var pipes: [Int32] = [0, 0]
    var rv = pipe(&pipes)
    guard rv == 0 else { fatalError("open pipe") }
    
    var attr: posix_spawnattr_t? = nil
    posix_spawnattr_init(&attr)
    defer { posix_spawnattr_destroy(&attr) }
        
    var actions: posix_spawn_file_actions_t? = nil
    posix_spawn_file_actions_init(&actions)
    defer { posix_spawn_file_actions_destroy(&actions) }
    
    let dev_null = strdup("/dev/null")
    defer { free(dev_null) }
    
    posix_spawn_file_actions_addopen(&actions, 0, dev_null, O_RDONLY, 0)
    
    posix_spawn_file_actions_adddup2(&actions, pipes[1], 1)
    if redirect {
        posix_spawn_file_actions_adddup2(&actions, pipes[1], 2)
    }
    
    posix_spawn_file_actions_addclose(&actions, pipes[0])
    posix_spawn_file_actions_addclose(&actions, pipes[1])
    
    let pid = posix_spawnp(args: arguments, environment: environment, attr: &attr, actions: &actions)
    
    posix_spawn_file_actions_destroy(&actions)
    
    rv = close(pipes[1])
    guard rv == 0 else { fatalError("close pipe") }
    
    let count = 4096
    var buf = [Int8](repeating: 0, count: count + 1)
    
    loop: while true {
        let n = read(pipes[0], &buf, count)
        switch n {
        case  -1:
            if errno == EINTR {
                continue
            } else {
                fatalError("\(errno)")
            }
        case 0:
            break loop
        default:
            buf[n] = 0
            if let string = String(validatingUTF8: buf) {
                closure(string)
            } else {
                fatalError("\(arguments[0])")
            }
        }
    }
    close(pipes[0])
    
    let status = wait(pid: pid)
    return status == 0
}

func posix_spawnp(args: [String], environment: [String: String] = [:], attr: inout posix_spawnattr_t?, actions: inout posix_spawn_file_actions_t?) -> pid_t {
    let argv = args.map { strdup($0) }
    defer { argv.forEach { free($0) } }
    
    let env = environment.map { strdup("\($0.0)=\($0.1)") }
    defer { env.forEach { free($0) } }
    
    var pid = pid_t()
    let errno = posix_spawnp(&pid, args.first, &actions, &attr, argv + [nil], env + [nil])
    guard errno == 0 else { fatalError("posix_spawnp") }
    
    return pid
}

func wait(pid: pid_t) -> Int32 {
    while true {
        var status: Int32 = 0
        let value = waitpid(pid, &status, 0)
        if value != -1 {
            let exit = (status >> 8) & 0xff
            if exit == 0 {
                return exit
            } else {
                return -1
            }
        } else if errno == EINTR {
            continue
        } else {
            return -1
        }
    }
}
