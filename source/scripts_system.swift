//
//  scripts_system.swift
//  utitool
//
//  Created by Macbook on 31.07.2025.
//

import Foundation

func install_script(name: String) {
    // Получаем текущую директорию проекта
    guard let projectDir = getCurrentScriptDirectory() else {
        print("Error: Could not determine project directory")
        return
    }
    
    // Создаем путь к папке scripts
    let scriptsDir = URL(fileURLWithPath: projectDir).appendingPathComponent("scripts")
    
    // Создаем директорию scripts, если её нет
    do {
        try FileManager.default.createDirectory(
            at: scriptsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
    } catch {
        print("Error creating scripts directory: \(error)")
        return
    }
    
    // Формируем URL для скачивания
    let urlString = "https://raw.githubusercontent.com/Intelektika-team/utinstall/main/script_\(name).py"
    guard let url = URL(string: urlString) else {
        print("Error: Invalid URL - \(urlString)")
        return
    }
    
    // Формируем путь для сохранения файла
    let outputFile = scriptsDir.appendingPathComponent("script_\(name).py")
    
    // Создаем задачу для curl
    let task = Process()
    task.launchPath = "/usr/bin/curl"
    task.arguments = ["-L", "-o", outputFile.path, url.absoluteString]
    
    // Настраиваем вывод
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    // Запускаем и ждем завершения
    do {
        try task.run()
        task.waitUntilExit()
        
        // Проверяем статус выполнения
        if task.terminationStatus == 0 {
            print("Successfully installed script: \(name)")
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Installation failed (status \(task.terminationStatus)): \(message)")
        }
    } catch {
        print("Error running curl: \(error)")
    }
}

