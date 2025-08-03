/*
  main.swift
  project utitool

  Created by Macbook on 24.07.2025.
  Tested on MacOS 11.7
*/
import Foundation
import CryptoKit


// MARK: Константы программы
let STAGE = "Release"
let VERSION = "0.9.5"
let NAME = "UTITOOL"
let AUTHOR = "Intelektika ~ PT ん"
let GITHUB_URL = "https://github.com/Intelektika-team"
let CONFIG_FILE = "userconfig.json"
let OLD_CONFIG_FILE = "~/olduserconfig.json"


// MARK: Модель конфигурации
struct Config: Codable {
    var username: String
    var passwordHash: String
    var version = VERSION
    var name = NAME
    var state = userstate
}

struct Old_Config: Codable {
    var username: String
    var passwordHash: String
    var version = VERSION
    var name = NAME
    var state = userstate
}

// MARK: Системные переменные
var config: Config!
var old_config: Config!
var rooted: Bool = false
var developer: Bool = false
var suspicious_activities:Double = 0
var userstate = "~"
var commandHistory: [String] = []
let developer_passwordhash = "0b11da411009ccf17e9ad8b1de6fb9a36e2848be4bdbfbb876d231adc521f784"
// Хеш пароля разработчика



// MARK: Запуск
if NAME == "UTITOOL" {
    main()
}
