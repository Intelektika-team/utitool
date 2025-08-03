//
//  systemutils.swift
//  utitool
//
//  Created by Macbook on 28.07.2025.
//

import Foundation
import MachO
import CryptoKit

public func showFordevSystemInfoNonStatic() {
    func getPageSize() -> UInt {
        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
            return 4096 // Значение по умолчанию
        }
        return UInt(pageSize)
    }
    
    func getMemoryUsage() -> (usedGB: Double, percent: Double) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0.0, 0.0)
        }
        
        let pageSize = getPageSize()
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let freeBytes = UInt64(stats.free_count) * UInt64(pageSize)
        let usedBytes = totalBytes - freeBytes
        
        let usedGB = Double(usedBytes) / 1_000_000_000.0
        let percent = Double(usedBytes) / Double(totalBytes) * 100.0
        
        return (usedGB, percent)
    }
    
    func getFreeDiskSpace() -> Double {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return 0.0
        }
        
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                return freeSize.doubleValue / 1_000_000_000.0
            }
        } catch {
            return 0.0
        }
        return 0.0
    }

    let processInfo = ProcessInfo.processInfo
    _ = processInfo.hostName
    _ = NSUserName()
    _ = Host.current().localizedName ?? "Unknown"
    
    // Архитектура
    var sysinfo = utsname()
    uname(&sysinfo)
    _ = withUnsafePointer(to: &sysinfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(validatingUTF8: $0) ?? "Unknown"
        }
    }
    
    // Версия macOS
    func runShell(_ command: String, args: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    _ = runShell("/usr/bin/sw_vers", args: ["-productName"]) ?? "macOS"
    _ = runShell("/usr/bin/sw_vers", args: ["-productVersion"]) ?? "Unknown"
    _ = runShell("/usr/bin/sw_vers", args: ["-buildVersion"]) ?? "Unknown"
    
    // Параметры системы
    _ = processInfo.processorCount
    let physicalMemory = processInfo.physicalMemory
    let physicalMemoryGB = Double(physicalMemory) / 1_000_000_000.0
    
    // Время работы
    let uptimeSeconds = Int(processInfo.systemUptime)
    let uptimeHours = uptimeSeconds / 3600
    let uptimeMinutes = (uptimeSeconds % 3600) / 60
    let uptimeSecs = uptimeSeconds % 60
    
    // Динамические параметры
    let (usedMemoryGB, memoryUsagePercent) = getMemoryUsage()
    let freeDiskSpaceGB = getFreeDiskSpace()

    print("""
    ================
    ram_memory \(physicalMemory)
    ram_memory_gb \(String(format: "%.2f", physicalMemoryGB))
    ram_used_gb \(String(format: "%.2f", usedMemoryGB))
    ram_usage_percent \(String(format: "%.1f", memoryUsagePercent))%
    disk_free_gb \(String(format: "%.2f", freeDiskSpaceGB))
    sys_uptime \(uptimeHours)h \(uptimeMinutes)m \(uptimeSecs)s
    """)
}






public func showSystemInfo() {
    // Получаем данные из system_profiler и uname
    let processInfo = ProcessInfo.processInfo
    let hostName = processInfo.hostName
    let userName = NSUserName()
    let computerName = Host.current().localizedName ?? "Unknown"
    
    // Архитектура процессора
    var sysinfo = utsname()
    uname(&sysinfo)
    let machine = withUnsafePointer(to: &sysinfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(validatingUTF8: $0) ?? "Unknown"
        }
    }
    
    // Получаем версию macOS через sw_vers
    func runShell(_ command: String, args: [String]) -> String? {
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            return nil
        }
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    let productName = runShell("/usr/bin/sw_vers", args: ["-productName"]) ?? "macOS"
    let productVersion = runShell("/usr/bin/sw_vers", args: ["-productVersion"]) ?? "Unknown"
    let buildVersion = runShell("/usr/bin/sw_vers", args: ["-buildVersion"]) ?? "Unknown"
    
    // Количество ядер CPU
    let cpuCount = ProcessInfo.processInfo.processorCount
    
    // Общий объем RAM
    let physicalMemory = ProcessInfo.processInfo.physicalMemory // в байтах
    let physicalMemoryGB = Double(physicalMemory) / 1024 / 1024 / 1024
    
    // Время работы системы
    let uptimeSeconds = ProcessInfo.processInfo.systemUptime
    let uptimeHours = Int(uptimeSeconds) / 3600
    let uptimeMinutes = (Int(uptimeSeconds) % 3600) / 60
    
    print("""
    
    Computer: \(computerName)
    Host: \(hostName)
    User name: \(userName)
    MacOS: \(productName) \(productVersion) Build \(buildVersion)
    Architecture: \(machine)
    Cpu cores: \(cpuCount)
    Ram memory: \(String(format: "%.2f", physicalMemoryGB)) GB
    System uptime: \(uptimeHours)h \(uptimeMinutes)m
    """)
}



public func getSystemResources() -> (totalMemoryGB: Double, freeMemoryGB: Double, cpuCount: Int, cpuUsagePercent: Double)? {
    // Получаем общее количество физической памяти
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    let totalMemoryGB = Double(totalMemory) / 1024 / 1024 / 1024

    // Получить количество ядер CPU
    let cpuCount = ProcessInfo.processInfo.processorCount

    // Получение информации о памяти с помощью host_statistics64
    
    var vmStats = vm_statistics64()
    var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let hostPort: mach_port_t = mach_host_self()
    
    let result = withUnsafeMutablePointer(to: &vmStats) { (vmStatPtr) -> kern_return_t in
        vmStatPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
        }
    }
    
    guard result == KERN_SUCCESS else {
        print(ANSIColor.red.apply(to: "Failed to fetch vm statistics"))
        return nil
    }
    
    // Размер страницы памяти (frame)
    let pageSize = UInt64(vm_kernel_page_size)
    
    // Рассчитываем свободную память: свободные + неактивные страницы
    let freeMemory = UInt64(vmStats.free_count + vmStats.inactive_count) * pageSize
    let freeMemoryGB = Double(freeMemory) / 1024 / 1024 / 1024

    // Рассчитываем загрузку CPU
    var cpuLoad = host_cpu_load_info()
    var cpuLoadCount = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
    let cpuResult = withUnsafeMutablePointer(to: &cpuLoad) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(cpuLoadCount)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &cpuLoadCount)
        }
    }
    
    guard cpuResult == KERN_SUCCESS else {
        print("Failed to fetch CPU load info")
        return nil
    }

    let user = Double(cpuLoad.cpu_ticks.0)
    let system = Double(cpuLoad.cpu_ticks.1)
    let idle = Double(cpuLoad.cpu_ticks.2)
    let nice = Double(cpuLoad.cpu_ticks.3)
    
    let totalTicks = user + system + idle + nice
    let busyTicks = user + system + nice
    
    let cpuUsagePercent = (totalTicks > 0) ? (busyTicks / totalTicks) * 100 : 0.0

    return (totalMemoryGB, freeMemoryGB, cpuCount, cpuUsagePercent)
}



public func convertToString(_ value: Any?) -> String {
    switch value {
    // Базовые типы
    case let str as String:
        return str
    case let num as NSNumber:
        return num.stringValue
    case let int as Int:
        return String(int)
    case let double as Double:
        return String(double)
    case let float as Float:
        return String(float)
    case let bool as Bool:
        return bool ? "true" : "false"
        
    // Коллекции
    case let array as [Any]:
        return "[\(array.map { convertToString($0) }.joined(separator: ", "))]"
    case let dict as [String: Any]:
        let pairs = dict.map { "\($0.key): \(convertToString($0.value))" }
        return "[\(pairs.joined(separator: ", "))]"
    case let set as Set<AnyHashable>:
        return "Set(\(convertToString(Array(set))))"
        
    // Даты
    case let date as Date:
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
        
    // Данные
    case let data as Data:
        return String(data: data, encoding: .utf8) ?? data.base64EncodedString()
        
    // Дефолтный случай
    default:
        return "\(value)"
    }
}

func getCurrentScriptDirectory() -> String? {
    // Получаем путь к исполняемому файлу (работает в скомпилированных приложениях)
    guard let executablePath = Bundle.main.executablePath else {
        return nil
    }
    let url = URL(fileURLWithPath: executablePath)
    return url.deletingLastPathComponent().path
}




public func compiler(command_i: String?, args_i: [String]?) {
    // Проверяем, что у нас есть и команда и аргументы (аргументы могут быть пустыми)
    guard let command = command_i else {
        // Если команда nil - просто выходим
        return
    }
    
    // Аргументы могут быть nil, в этом случае используем пустой массив
    let arguments = args_i ?? []
    
    // Добавляем команду в историю
    commandHistory.append(command)
    
    // Приводим команду к нижнему регистру и обрабатываем
    switch command.lowercased() {
    case "script", "scr":
        guard let path = getCurrentScriptDirectory() else {
            print("Error: Could not determine script directory")
            break
        }
        
        guard !arguments.isEmpty else {
            print("Error: Python script name is required")
            break
        }
        
        let scriptName = arguments[0]
        var scriptArgs = ""
        
        // Обрабатываем дополнительные аргументы, если они есть
        if arguments.count > 1 {
            // Объединяем все аргументы после имени скрипта в строку
            let additionalArgs = arguments[1...].map { "\"\($0)\"" }.joined(separator: ", ")
            scriptArgs = additionalArgs
        }
        
        let pythonScript = """
        import sys
        sys.path.append("\(path)")
        try:
            from scripts.script_\(scriptName) import main
            result = main(\(scriptArgs))
            print(result)
        except ImportError as e:
            print(f"Import error: {e}")
        except Exception as e:
            print(f"Error: {e}")
        """
        
        let result = runPythonScript(script: pythonScript)
        print(result)
            
    
    case "scri", "script-install":
        guard !arguments.isEmpty else {
            print("Error: Script name is required. Usage: script-install <name>")
            break
        }
        
        let scriptName = arguments[0]
        
        // Проверяем, что имя не содержит запрещенных символов
        guard scriptName.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil else {
            print("Error: Invalid script name. Use only alphanumeric characters.")
            break
        }
        
        install_script(name: scriptName)
        
        
    case "help":
        showHelp()
        
    case "devmode":
        fordevelop()
        
    case "devmode-exit":
        if developer {
            if requestAndVerifyPassword() {
                developer = false
                rooted = false
                userstate = "~"
            } else {
                developer = false
                rooted = false
                userstate = "~"
                suspicious_activities += 1
            }
        } else {
            print("You are not developer")
        }
        
    case "system":
        processSystemCommand(arguments: arguments)
        
    case "exit":
        print("Exiting program...")
        exit(0)
        
    case "admin":
        sudo(arguments: arguments)
        
    case "dev":
        processDevCommand(arguments)
        
    case "setname":
        if rooted {
            if !arguments.isEmpty {
                config.username = arguments[0]
                saveConfig()
                print("Username set to \(arguments[0])")
            } else {
                print("Please provide a new username")
            }
        } else {
            print("You must be root")
        }
        
    case "history":
        print(commandHistory.enumerated().map { "\($0): \($1)" }.joined(separator: "\n"))
        
    case "about":
        showAbout()
        
    case "app":
        if arguments.isEmpty {
            print("Please specify application name, e.g. 'app Safari' or 'app \"Google Chrome\"'")
            return
        }
        
        let appName = arguments.joined(separator: " ")
        let applicationsPath = "/Applications/\(appName).app"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: applicationsPath) else {
            print("Application '\(appName)' not found in /Applications")
            return
        }
        
        // Экранирование для безопасности
        let escapedAppName = appName.replacingOccurrences(of: "'", with: "'\\''")
        let shellCommand = "open '/Applications/\(escapedAppName).app'"
        
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", shellCommand]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to launch process: \(error)")
        }
        
    case "clear":
        terminal_clear()
        
    case "":
        return
        
    default:
        print("Unknown command: '\(command)'. Type 'help' for available commands.")
    }
}



public func verifyPassword(password: String) -> Bool {
    // Для проверки пароля используем sudo -k для сброса таймаута и sudo -S -v для проверки пароля из stdin
    let task = Process()
    task.launchPath = "/usr/bin/sudo"
    task.arguments = ["-k", "-S", "-v"] // -k сброс старой аутентификации, -S читать пароль из stdin

    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.standardInput = inputPipe
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    do {
        try task.run()
        
        if let passwordData = (password + "\n").data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(passwordData)
            inputPipe.fileHandleForWriting.closeFile()
        }

        task.waitUntilExit()

        return task.terminationStatus == 0
    } catch {
        return false
    }
}

/// Основная функция — показывает окно, запрашивает пароль, проверяет его, возвращает true/false
public func requestAndVerifyPassword() -> Bool {
    guard let password = requestPassword() else {
        print("Password entry canceled or failed.")
        return false
    }
    let verified = verifyPassword(password: password)
    if !verified {
        print(ANSIColor.red.apply(to: "Password verification failed."))
    }
    return verified
}

public func requestPassword() -> String? {
    let appleScript = """
    display dialog "Please enter your password:" default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK"
    """

    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", appleScript]

    let pipe = Pipe()
    task.standardOutput = pipe

    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
        return nil
    }
    // В ответе ожидается что-то вроде: button returned:OK, text returned:<password>
    if let range = output.range(of: "text returned:") {
        let password = output[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return password
    }
    return nil
}


func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
