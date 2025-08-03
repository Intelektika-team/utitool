//
//  teminal.swift
//  utitool
//
//  Created by Macbook on 29.07.2025.
//

import Foundation

enum ANSIColor: String {
    case reset = "\u{001B}[0m"
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case brightBlack = "\u{001B}[0;90m"
    case brightRed = "\u{001B}[0;91m"
    case brightGreen = "\u{001B}[0;92m"
    case brightYellow = "\u{001B}[0;93m"
    case brightBlue = "\u{001B}[0;94m"
    case brightMagenta = "\u{001B}[0;95m"
    case brightCyan = "\u{001B}[0;96m"
    case brightWhite = "\u{001B}[0;97m"
    
    func apply(to text: String) -> String {
        return self.rawValue + text + ANSIColor.reset.rawValue
    }
}

public func inputProcess_classic(prompt: String = "") -> (command: String, arguments: [String]?) {
    print(prompt, terminator: "")
    fflush(stdout)
    
    guard let input = readLine(strippingNewline: false)?.trimmingCharacters(in: .newlines),
          !input.isEmpty else {
        return ("", nil)
    }
    
    let parts = input.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    if !parts.isEmpty {
        commandHistory.append(input)
    }
    
    guard let first = parts.first else {
        return ("", nil)
    }
    
    let arguments = Array(parts.dropFirst())
    return (first, arguments.isEmpty ? nil : arguments)
}

public func processTerminal() {
    let fileManager = FileManager.default
    let desktopPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    fileManager.changeCurrentDirectoryPath(desktopPath.path)
    terminal_clear()
    
    print("\n" + ANSIColor.brightGreen.apply(to: "==== uBash v\(VERSION) started ===="))
    print(ANSIColor.brightCyan.apply(to: "Type 'exit' to return to main shell\n"))
    
    // Для отслеживания предыдущего пути при cd -
    var previousPath = fileManager.currentDirectoryPath
    
    // Для истории команд
    var historyIndex = commandHistory.count
    
    func nanoEditor(filename: String) {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(filename)
        var lines: [String] = []
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let content = try? String(contentsOf: fileURL) {
                lines = content.components(separatedBy: .newlines)
            }
        }
        
        if lines.isEmpty {
            lines.append("")
        }
        
        var currentLineIndex = 0
        var unsavedChanges = false
        
        func displayEditor() {
            print("\u{001B}[2J\u{001B}[H") // Clear screen
            print("=== Editing: \(filename) ===")
            print("=== Line \(currentLineIndex + 1)/\(lines.count) | \(unsavedChanges ? "UNSAVED" : "saved") ===")
            print("================================\n")
            
            let startIndex = max(0, currentLineIndex - 5)
            let endIndex = min(lines.count, startIndex + 10)
            
            for index in startIndex..<endIndex {
                if index == currentLineIndex {
                    print("> [\(index + 1)] \(lines[index])")
                } else {
                    print("  [\(index + 1)] \(lines[index])")
                }
            }
            
            print("\n==================================================")
            print("Commands: ↑/↓: navigate, Enter: edit, a: add line")
            print("d: delete, s: save, x: exit, ?: help")
            print("==================================================")
        }
        
        func showHelp() {
            print("\n=== Nano Help ===")
            print("Enter: Edit current line")
            print("a: Add new line after current")
            print("d: Delete current line")
            print("s: Save file")
            print("x: Exit (prompt if unsaved)")
            print("↑/k: Move up")
            print("↓/j: Move down")
            print("b: Move to beginning")
            print("e: Move to end")
            print("?: Show this help")
            print("=================\n")
        }
        
        editorLoop: while true {
            displayEditor()
            print("\nCommand: ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                continue
            }
            
            switch input {
            case "", "edit", "e":
                print("\nEditing line \(currentLineIndex + 1). Enter new content:")
                if let newLine = readLine() {
                    lines[currentLineIndex] = newLine
                    unsavedChanges = true
                }
                
            case "n", "down", "j", "^[[B":
                currentLineIndex = min(currentLineIndex + 1, lines.count - 1)
                
            case "p", "up", "k", "^[[A":
                currentLineIndex = max(currentLineIndex - 1, 0)
                
            case "a", "add":
                print("\nEnter new line content:")
                if let newLine = readLine() {
                    lines.insert(newLine, at: currentLineIndex + 1)
                    currentLineIndex += 1
                    unsavedChanges = true
                }
                
            case "d", "delete":
                if lines.count > 1 {
                    lines.remove(at: currentLineIndex)
                    if currentLineIndex >= lines.count {
                        currentLineIndex = lines.count - 1
                    }
                    unsavedChanges = true
                } else {
                    print("\nCan't delete the only line")
                }
                
            case "s", "save":
                do {
                    let content = lines.joined(separator: "\n")
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    unsavedChanges = false
                    print("\nFile saved successfully!")
                    sleep(1)
                } catch {
                    print("\nError saving file: \(error)")
                    sleep(2)
                }
                
            case "x", "exit":
                if unsavedChanges {
                    print("\nYou have unsaved changes. Save before exit? (y/n): ", terminator: "")
                    if let response = readLine()?.lowercased(), response == "y" {
                        do {
                            let content = lines.joined(separator: "\n")
                            try content.write(to: fileURL, atomically: true, encoding: .utf8)
                            print("File saved. Exiting...")
                        } catch {
                            print("Save failed: \(error)")
                        }
                    }
                }
                break editorLoop
                
            case "b", "beginning":
                currentLineIndex = 0
                
            case "e", "end":
                currentLineIndex = lines.count - 1
                
            case "?", "help":
                showHelp()
                print("\nPress Enter to continue...")
                _ = readLine()
                
            default:
                print("\nUnknown command: \(input)")
                sleep(1)
            }
        }
    }
    
    while true {
        let currentPath = fileManager.currentDirectoryPath
        let homePath = fileManager.homeDirectoryForCurrentUser.path
        let relativePath = currentPath.replacingOccurrences(of: homePath, with: "~")
        
        // Определение цвета в зависимости от привилегий
        let userColor: ANSIColor = rooted ? .brightRed : (developer ? .brightYellow : .brightGreen)
        let stateColor: ANSIColor = rooted ? .red : (developer ? .yellow : .green)
        let pathColor: ANSIColor = .brightCyan
        
        // Формирование приглашения
        let userPrompt = userColor.apply(to: config.username)
        let statePrompt = stateColor.apply(to: userstate)
        let pathPrompt = pathColor.apply(to: relativePath)
        
        let prompt = "\n\(userPrompt)\(statePrompt) [\(pathPrompt)] "
        
        let input = inputProcess_classic(prompt: prompt)
        guard !input.command.isEmpty else { continue }
        
        // Обработка специальных команд
        switch input.command.lowercased() {
        case "exit", "quit":
            return
            
        case "cd":
            let currentPathBeforeChange = fileManager.currentDirectoryPath
            
            if let path = input.arguments?.first {
                var targetPath: String
                
                // Обработка cd -
                if path == "-" {
                    targetPath = previousPath
                    previousPath = currentPathBeforeChange
                }
                // Обработка домашней директории
                else if path == "~" {
                    targetPath = fileManager.homeDirectoryForCurrentUser.path
                    previousPath = currentPathBeforeChange
                }
                // Обработка относительных путей
                else {
                    if path.hasPrefix("/") {
                        targetPath = path
                    } else {
                        targetPath = currentPathBeforeChange + "/" + path
                    }
                    previousPath = currentPathBeforeChange
                }
                
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: targetPath, isDirectory: &isDirectory), isDirectory.boolValue {
                    fileManager.changeCurrentDirectoryPath(targetPath)
                } else {
                    print(ANSIColor.red.apply(to: "cd: no such directory: \(path)"))
                }
            } else {
                // cd без аргументов - переход в домашнюю директорию
                previousPath = currentPathBeforeChange
                fileManager.changeCurrentDirectoryPath(fileManager.homeDirectoryForCurrentUser.path)
            }
            continue
            
        case "nano":
            if let filename = input.arguments?.first {
                nanoEditor(filename: filename)
            } else {
                print(ANSIColor.red.apply(to: "Usage: nano <filename>"))
            }
            continue
            
        case "history":
            print("\nCommand history:")
            for (index, cmd) in commandHistory.enumerated() {
                print("\(index + 1): \(cmd)")
            }
            continue
            
        case "clear":
            terminal_clear()
            continue
            
        default:
            break
        }
        
        // Обработка интерактивных команд
        if ["sudo", "su", "ssh", "mysql", "psql", "sqlite3", "telnet"].contains(input.command.lowercased()) {
            print(ANSIColor.brightYellow.apply(to: "\n=== Starting interactive session ==="))
            print(ANSIColor.brightYellow.apply(to: "Type 'exit' to return to uBash\n"))
            
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = [input.command] + (input.arguments ?? [])
            
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            task.standardInput = inputPipe
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            // Запускаем процесс
            task.launch()
            
            // Обработка вывода в реальном времени
            let outputQueue = DispatchQueue(label: "output-queue")
            var outputData = Data()
            var errorData = Data()
            
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    outputQueue.async {
                        outputData.append(data)
                        if let str = String(data: data, encoding: .utf8) {
                            print(str, terminator: "")
                            fflush(stdout)
                        }
                    }
                }
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    outputQueue.async {
                        errorData.append(data)
                        if let str = String(data: data, encoding: .utf8) {
                            print(ANSIColor.red.apply(to: str), terminator: "")
                            fflush(stdout)
                        }
                    }
                }
            }
            
            // Обработка ввода пользователя
            while task.isRunning {
                guard let userInput = readLine(strippingNewline: false) else { continue }
                
                // Выход из интерактивного режима
                if userInput.trimmingCharacters(in: .newlines) == "exit" {
                    task.interrupt()
                    break
                }
                
                if let inputData = userInput.data(using: .utf8) {
                    inputPipe.fileHandleForWriting.write(inputData)
                }
            }
            
            // Завершение
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            task.waitUntilExit()
            print(ANSIColor.brightYellow.apply(to: "\n=== Interactive session ended ==="))
            continue
        }
        
        // Обработка обычных команд
        let task = Process()
        task.launchPath = "/bin/bash"
        
        var fullCommand = input.command
        if let arguments = input.arguments {
            fullCommand += " " + arguments.joined(separator: " ")
        }
        
        task.arguments = ["-c", fullCommand]
        task.standardInput = FileHandle.standardInput
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus != 0 {
                print(ANSIColor.red.apply(to: "Command exited with code \(task.terminationStatus)"))
            }
        } catch {
            print(ANSIColor.red.apply(to: "Command failed: \(error.localizedDescription)"))
        }
    }
}
