/*
  utils.swift
  project utitool

  Created by Macbook on 25.07.2025.
  Tested on MacOS 11.7
  State: Development
*/

import Cocoa
import Darwin
import Foundation
import CryptoKit

// MARK: Функции работы с конфигурацией
func loadConfig() -> Config? {
    let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(CONFIG_FILE)
    
    guard let data = try? Data(contentsOf: fileURL) else {
        return nil
    }
    
    return try? JSONDecoder().decode(Config.self, from: data)
}

func loadOldConfig() -> Config? {
    let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(OLD_CONFIG_FILE)
    
    guard let data = try? Data(contentsOf: fileURL) else {
        return nil
    }
    
    return try? JSONDecoder().decode(Config.self, from: data)
}

func saveConfig() {
    let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(CONFIG_FILE)
    
    guard let data = try? JSONEncoder().encode(config) else {
        print("Error: Failed to encode configuration")
        return
    }
    
    do {
        try data.write(to: fileURL)
    } catch {
        print("Error saving config: \(error)")
    }
}

func saveOld_Config() {
    let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(OLD_CONFIG_FILE)
    
    guard let data = try? JSONEncoder().encode(old_config) else {
        print("Error: Failed to encode configuration")
        return
    }
    
    do {
        try data.write(to: fileURL)
    } catch {
        print("Error saving config: \(error)")
    }
}

// MARK: - Plugin System Functions
func runPythonScript(script: String) -> String {
    let tempFile = "\(NSTemporaryDirectory())plugin_\(UUID().uuidString).py"
    do {
        try script.write(toFile: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: tempFile)
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", tempFile]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return "Error: Could not decode script output"
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return "Error executing plugin: \(error)"
    }
}



func runPythonScriptOtput(script: String) -> String {
    let tempFile = "\(NSTemporaryDirectory())plugin_\(UUID().uuidString).py"
    do {
        try script.write(toFile: tempFile, atomically: true, encoding: .utf8)
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", tempFile]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        try FileManager.default.removeItem(atPath: tempFile)
        
        if let output = String(data: data, encoding: .utf8) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Error: Could not decode script output."
        }
    } catch {
        return "Error executing plugin: \(error)"
    }
}



// MARK: Системные функции


func makeTerminalFullscreen() {
    let appleScriptSource = """
    tell application "Terminal"
        activate
        tell application "System Events"
            tell process "Terminal"
                set frontmost to true
                try
                    click menu item "Enter Full Screen" of menu "Window" of menu bar 1
                end try
            end tell
        end tell
    end tell
    """

    let script = NSAppleScript(source: appleScriptSource)
    var error: NSDictionary? = nil
    script?.executeAndReturnError(&error)

    if let error = error {
        print("AppleScript error: \(error)")
    }
}



func terminal_clear() {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["clear"]
    task.launch()
    task.waitUntilExit()
}

public func inputProcess() -> (command: String, arguments: [String]?) {
    guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
          !input.isEmpty else {
        return ("", nil)
    }
    
    let parts = input.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    commandHistory.append(input)
    return (parts[0].lowercased(), parts.count > 1 ? Array(parts[1...]) : nil)
}


public func showHelp() {
    print(ANSIColor.brightCyan.apply(to: """
    \n=== \(NAME) v\(VERSION) - Command Help ===
    \(ANSIColor.reset.rawValue)
    \(ANSIColor.brightBlue.apply(to: "Basic Commands:"))
      help           - Show this help message
      about          - Show program information
      exit           - Exit the program
      clear          - Clear terminal screen
      history        - Show command history
    
    \(ANSIColor.brightBlue.apply(to: "User Management:"))
      setname <name> - Change your username (requires root)
    
    \(ANSIColor.brightBlue.apply(to: "Application Control:"))
      app <name>     - Launch application from /Applications
    
    \(ANSIColor.brightBlue.apply(to: "System Information:"))
      system --info    - Show program info
      system --sys     - Show system information
      system --sys-use - Show resource usage (CPU, RAM)
      system --all     - Show all available information
      system reset-password    - Reset password to default
      system reset-config      - Reset configuration

    
    \(ANSIColor.brightBlue.apply(to: "Privilege Management:"))
      admin root      - Enter root mode
      admin exit-root - Exit root mode
      admin -susp     - Show suspicious activity counter
      admin ?         - Check root status
    
    \(ANSIColor.brightBlue.apply(to: "Developer Tools:"))
      devmode         - Enter developer mode
      devmode-exit    - Exit developer mode
    
    \(ANSIColor.brightBlue.apply(to: "Advanced Features:"))
      system zsh|bash|terminal - Open terminal shell
      system change-password   - Change root password

    \(ANSIColor.reset.rawValue)For more details, visit: \(GITHUB_URL)
    """))
}

public func showAbout() {
    print(ANSIColor.brightCyan.apply(to: """
    \n=== About \(NAME) v\(VERSION) ===
    \(ANSIColor.reset.rawValue)
    \(ANSIColor.brightWhite.apply(to: "Description:"))
    Powerful macOS utility tool designed for developers and power users.
    Provides system management, monitoring and automation capabilities.
    
    \(ANSIColor.brightWhite.apply(to: "Features:"))
    - System information and monitoring
    - Application management
    - User and privilege control
    - Developer tools
    - Terminal integration
    
    \(ANSIColor.brightWhite.apply(to: "Technical Details:"))
    - Written in Swift \(ProcessInfo.processInfo.operatingSystemVersionString)
    - Uses native macOS APIs
    - SHA-256 password hashing
    - Full terminal compatibility
    
    \(ANSIColor.brightWhite.apply(to: "Development Status:"))
    - Stage: \(STAGE)
    - Version: \(VERSION)
    - Last Update: \(Date())
    
    \(ANSIColor.brightWhite.apply(to: "Author Information:"))
    - Created by: \(AUTHOR)
    - GitHub: \(GITHUB_URL)
    - Absolutely humanmade, no AI used. ん
    
    \(ANSIColor.brightWhite.apply(to: "System Requirements:"))
    - macOS 11.7 or later
    - Swift 5.0+
    - X86-64 or ARM architecture
    
    \(ANSIColor.brightRed.apply(to: "Warning:"))
    This tool requires careful use with root privileges.
    Improper use may affect system stability.
    
    \(ANSIColor.reset.rawValue)Type 'help' for available commands or visit our GitHub for documentation.
    """))
}

public func showVersion() {
    print("\(NAME) v\(VERSION)")
}

func showFordevSystemInfoStatic() {
    func getSysCtlString(property: String) -> String? {
        var size = 0
        guard sysctlbyname(property, nil, &size, nil, 0) == 0 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname(property, &value, &size, nil, 0) == 0 else { return nil }
        return String(cString: value)
    }
    
    func getSysCtlInt(property: String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        guard sysctlbyname(property, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }
    
    func getTotalDiskSpace() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemSize] as? Int64
        } catch {
            return nil
        }
    }
    
    let processInfo = ProcessInfo.processInfo
    let hostName = processInfo.hostName
    let userName = NSUserName()
    let computerName = Host.current().localizedName ?? "Unknown"
    
    // Информация о системе
    var sysinfo = utsname()
    uname(&sysinfo)
    let machine = withUnsafePointer(to: &sysinfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(validatingUTF8: $0) ?? "Unknown"
        }
    }
    
    // Версия macOS
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
    
    let model = getSysCtlString(property: "hw.model") ?? "Unknown"
    let cpuBrand = getSysCtlString(property: "machdep.cpu.brand_string") ?? "Unknown"
    let physicalCores = getSysCtlInt(property: "hw.physicalcpu") ?? 0
    let logicalCores = getSysCtlInt(property: "hw.logicalcpu") ?? 0
    let physicalMemory = processInfo.physicalMemory
    let physicalMemoryGB = Double(physicalMemory) / 1e9
    let totalDiskBytes = getTotalDiskSpace() ?? 0
    let totalDiskGB = Double(totalDiskBytes) / 1e9

    print("""
    computer_name \(computerName)
    host_name \(hostName)
    user_name \(userName)
    mac_os_info \(productName) \(productVersion) (\(buildVersion))
    architecture \(machine)
    compoter_model \(model)
    cpu_from \(cpuBrand)
    physical_cores \(physicalCores)
    logical_cores \(logicalCores)
    ram_memory \(String(format: "%.2f GB", physicalMemoryGB)) (\(physicalMemory) bytes)
    disk_info \(String(format: "%.2f GB", totalDiskGB)) (\(totalDiskBytes) bytes)
    """)
}




public func showInfo() {
    print("""
    ====== Program info ======
    \(NAME) \(STAGE) v\(VERSION)
    Author: \(AUTHOR)
    Absolutely んumanmade, no AI
    System requirements:
    MacOS: 11.7+
    Swift: 5+
    Security:
    🔒 Passwords stored as SHA-256 hashes
    Our GitHub: \(GITHUB_URL)
    """)
}

public func sudo(arguments: [String]?) {
    guard let args = arguments, !args.isEmpty else {
        print("Admin command requires arguments. Use 'admin -h' for help.")
        return
    }
    
    switch args[0] {
    case "root":
        if suspicious_activities <= 3{
            if !rooted {
                print("Enter password:")
                if let input = readLine() {
                    let inputHash = sha256(input)
                    if inputHash == config.passwordHash {
                        rooted = true
                        userstate = "@"
                        print("Root access granted")
                    } else {
                        suspicious_activities += 0.5
                        print(ANSIColor.yellow.apply(to: "Authentication failed"))
                    }
                }
            } else {
                print("You already in root mode")
            }
        }
        else{
            suspicious_activities += 1
            print(ANSIColor.red.apply(to: "Root acces isn't granted, you are suspicious"))
        }
        
    case "exit-root":
        if rooted {
            rooted = false
            userstate = "~"
            print("Root access revoked")
        } else {
            print("You are not in root mode")
        }
        
    case "?":
        print(rooted ? "Root access: ACTIVE" : "Root access: INACTIVE")
    
    case "-susp":
        print("Your activity - ", suspicious_activities)
        
    case "-h":
        print("""
        Admin commands:
        root       - enter root mode
        exit-root  - exit root mode
        -susp      - show your activity traffic
        ?          - check root status
        """)
    
    case "--run":
        guard args.count >= 2 else {
            print("Usage: --run <command> [arguments]")
            return
        }
        
        let commandToRun = Array(args[1...]) // Конвертируем ArraySlice в Array
        let command = commandToRun[0]
        let commandArgs = Array(commandToRun.dropFirst()) // Безопасно получаем остальные аргументы
        
        if requestAndVerifyPassword() {
            rooted = true
            compiler(command_i: command, args_i: commandArgs)
            rooted = false
        } else {
            print("Authentication failed")
            suspicious_activities += 1
        }
        
        
        
    default:
        print(ANSIColor.red.apply(to: "Unknown admin command. Use 'admin -h' for help."))
    }
}


public func showAllInfo(){
    showAbout()
    showInfo()
    showSystemInfo()
}

public func processSystemCommand(arguments: [String]?) {
    guard rooted || developer else {
        print("Root access required. Use 'admin root'.")
        return
    }
    
    guard let args = arguments, !args.isEmpty else {
        print("System command requires arguments. Use 'help' for options.")
        return
    }
    
    switch args[0] {
    case "--ver":
        showVersion()
        
    case "--info":
        showInfo()
    
    case "--sys":
        showSystemInfo()
    
    case "--about":
        showAbout()
    
    case "--all":
        showAllInfo()
    
    case "-h", "-help", "help", "h":
        print("""
Avialable system commands -
--ver : show utitool version
--info : show info
--about : show about
--all : show version, info, about
cmd/terminal/bash : start uBash
--sys-use : show system use
change-password : change password
reset-config : reset config
reset-password : reset password
""")
        
    case "zsh", "cmd", "bash", "terminal":
        processTerminal()
    
    case "--sys-use":
        if let resources = getSystemResources() {
            print("======================")
            print(String(format: "Total Memory: %.2f GB", resources.totalMemoryGB))
            print(String(format: "Free Memory: %.2f GB", resources.freeMemoryGB))
            print("CPU Cores: \(resources.cpuCount)")
            print(String(format: "CPU Usage: %.2f%%", resources.cpuUsagePercent))
        } else {
            print(ANSIColor.red.apply(to: "Failed to retrieve system resources info."))
        }
        
    case "change-password":
        print("Enter your old password:")
        guard var oldPass = readLine(), !oldPass.isEmpty else {
            print(ANSIColor.red.apply(to: "Invalid password"))
            return
        }
        oldPass = sha256(oldPass)
        if oldPass == config.passwordHash{
            print("Enter new password:")
            guard let newPass = readLine(), !newPass.isEmpty else {
                print(ANSIColor.red.apply(to: "Invalid password"))
                return
            }
            
            print("Confirm new password:")
            if let confirmPass = readLine(), newPass == confirmPass {
                config.passwordHash = sha256(newPass)
                saveConfig()
                print("Password changed successfully")
            } else {
                print("Passwords do not match")
            }
        } else {
            suspicious_activities += 0.5
            print(ANSIColor.red.apply(to: "Password do not match"))
        }
    
    case "reset-password":
        let defaultHash = sha256("1234")
        config.passwordHash = defaultHash
        saveConfig()
        print("Password reset to default")
    
    case "reset-config":
        config = Config(
            username: "user",
            passwordHash: sha256("1234")
        )
        saveConfig()
        print("Configuration reset to default values")
        
    default:
        print(ANSIColor.yellow.apply(to: "Unknown system command. Use 'help' for options."))
    }
}


public func fordevelop(){
    if config.username == "utidevpeople" && !developer{
        print("Input developer password- ", terminator: "")
        let input:String? = readLine()
        if sha256(convertToString(input)) == developer_passwordhash{
            if requestAndVerifyPassword(){
                developer = true
                rooted = true
                userstate = "$"
                print(ANSIColor.white.apply(to: "Devmode turn on"))
            }
        }else{
            print(ANSIColor.yellow.apply(to: "Develop mode isn't tunrn."))
        }
    }else if developer{
        print("You were already a developer")
    }else{
        print(ANSIColor.yellow.apply(to: "Develop mode isn't tunrn."))
    }
}

public func process_app(_ arguments: [String]?) {
    guard let args = arguments, !args.isEmpty else {
        print("Please specify the application name, e.g. 'app Telegram'.")
        print("Available shortcuts: telegram, vscode, xcode, or any app from /Applications.")
        return
    }

    let appName: String
    switch args[0].lowercased() {
    case "telegram":
        appName = "Telegram"
    case "vscode":
        appName = "Visual Studio Code"
    case "xcode":
        appName = "Xcode"
    default:
        appName = args[0]
        print("Trying to launch \(appName) from /Applications...")
    }

    let applicationPath = "/Applications/\(appName).app"
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: applicationPath) else {
        print(ANSIColor.red.apply(to: "Application '\(appName)' not found in /Applications."))
        return
    }

    let escapedAppName = appName.replacingOccurrences(of: "'", with: "'\\''")
    let shellCommand = "open '/Applications/\(escapedAppName).app'"

    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", shellCommand]

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        print(ANSIColor.red.apply(to: "Failed to launch process: \(error)"))
    }
}


public func processDevCommand(_ arguments: [String]?) {
    guard let args = arguments, !args.isEmpty else {
        print("Input must be isn't empty")
        return
    }
    if !developer{
       print("Failed processing, you must be in devmode")
    } else{
        switch args[0].lowercased() {
        case "-rsuspa":
            suspicious_activities = 0
            
        case "--setsuspa":
            guard args.count > 1, let newValue = Double(args[1]) else {
                print("Please provide a valid integer value after --setSuspA")
                return
            }
            suspicious_activities = newValue
        
        case "--sys":
            guard let arg = readLine(), !arg.isEmpty else {
                print(ANSIColor.red.apply(to: "inguard sys error"))
                return
            }
            do{
            switch arg.lowercased(){
            case "-s":
                showFordevSystemInfoStatic()
            case "-d":
                showFordevSystemInfoNonStatic()
            default:
                print("unknown")
            }
            }catch{
                print("\(error)")
            }
        
            
        case "root":
            guard args.count >= 2 else{
                print("inguard root error")
                return
            }
            switch args[1].lowercased(){
            case "-on":
                rooted = true
                
            case "-off":
                rooted = false
                
            case "--set-usst":
                saveOld_Config()
                if !args[2].isEmpty{
                    userstate = args[2].lowercased()
                    config.state = userstate
                }
            
            case "--set-ver":
                saveOld_Config()
                if !args[2].isEmpty{
                    config.version = args[2].lowercased()
                }

                
            case "--set-name":
                saveOld_Config()
                if !args[2].isEmpty{
                    config.name = args[2].lowercased()
                }
            
            case "-save":
                saveConfig()
            
            case "-load":
                config = loadConfig()
            
            case "-undo":
                config = loadOldConfig()
            
            default:
                print("unknown")
            }
            
        default:
            print("Unknown command")
        }
    }
}


public func installPythonDependencies() {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["pip3", "install", "psutil"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        print("Installing Python dependencies...")
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }
    } catch {
        print("Error installing dependencies: \(error)")
    }
}






// MARK: Основа
public func main() {
    print("\n\n")
    if let loadedConfig = loadConfig() {
        config = loadedConfig
    } else {
        // Создание дефолтной конфигурации
        config = Config(
            username: "user",
            passwordHash: sha256("1234")
        )
        saveConfig()
        print("Created new configuration")
    }
    
    print("""
 :.:    :.: :.:.:.:.:.: :.:.:.:.:.: :.:.:.:.:.: :.:.:.:.   :.:.:.:.  :.:
 :+:    :+:     :+:         :+:         :+:    :+:    :+: :+:    :+: :+:
 +:+    +:+     +:+         +:+         +:+    +:+    +:+ +:+    +:+ +:+
 +#+    +:+     +#+         +#+         +#+    +#+    +:+ +#+    +:+ +:+
 +#+    +#+     +#+         +#+         +#+    +#+    +#+ +#+    +#+ +#+
 #+#    #+#     #+#         #+#         #+#    #+#    #+# #+#    #+# #+#
  ########      ###     ###########     ###     ########   ########  ##########
\n\n
""")
    
    print("\n\n" + ANSIColor.white.apply(to: "========  Welcome to "), terminator: "")
    print(ANSIColor.cyan.apply(to: "\(NAME) v\(VERSION)  \(ANSIColor.white.apply(to: "========"))"))
    print("""
    \(ANSIColor.white.apply(to: "Type 'help' for available commands and 'exit' to quit"))
    \(ANSIColor.white.apply(to: "Author: \(ANSIColor.cyan.apply(to: AUTHOR))"))
    """)
    
    while true {
        print("\n", ANSIColor.green.apply(to:"\(config.username) \(userstate) "), terminator: "")
        guard let (command, arguments) = Optional(inputProcess()) else {
            continue
        }
        compiler(command_i: command, args_i: arguments)
    }
}
