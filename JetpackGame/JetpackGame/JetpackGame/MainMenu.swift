//
//  testing.swift
//  JetpackGame
//
//  Created by Marfenko Mykhailo on 15/01/2024.
//

import UIKit
import SpriteKit
import GameplayKit

class MainMenu: SKScene {

    var restartButton:SKSpriteNode!
    var difficultyButton:SKSpriteNode!
    var difficultyLabel:SKLabelNode!
    let difficulties = ["Baby dont hurt me", "Easy", "Medium", "Hard", "ULTRA HARDCORE!!!"]

    override func didMove(to view: SKView) {
        restartButton = self.childNode (withName: "restartButton") as? SKSpriteNode
        difficultyButton = self.childNode(withName: "difficultyButton") as? SKSpriteNode
        difficultyLabel = self.childNode(withName: "difficultyLabel") as? SKLabelNode

        changeLabel()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first

        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes (at: location)
        
            if nodesArray.first?.name == "restartButton" {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                if let gameScene = GameScene(fileNamed: "GameScene") {
                    gameScene.scaleMode = .aspectFill
                    self.view?.presentScene(gameScene, transition: transition)
                }
            }
            else if nodesArray.first?.name == "difficultyButton" {
                changeDifficulty()
            }
        }
    }

    func changeLabel() {
        let userDefaults = UserDefaults.standard
        let currentDifficulty = userDefaults.string(forKey: "currentDifficulty") ?? "Medium"
        difficultyLabel.fontColor = colorForDifficulty(currentDifficulty)
        difficultyLabel.text = currentDifficulty
        print("Difficulty: \(currentDifficulty), Color: \(colorForDifficulty(currentDifficulty))")

    }

    func colorForDifficulty(_ difficulty: String) -> UIColor {
        switch difficulty {
        case "Baby dont hurt me":
            return UIColor.blue
        case "Easy":
            return UIColor.green
        case "Medium":
            return UIColor.yellow
        case "Hard":
            return UIColor.orange
        case "ULTRA HARDCORE!!!":
            return UIColor.red
        default:
            return UIColor.white
        }
    }

    func changeDifficulty() {
        let userDefaults = UserDefaults.standard
        let currentDifficulty = userDefaults.string(forKey: "currentDifficulty") ?? "Medium"

        if let currentIndex = difficulties.firstIndex(of: currentDifficulty) {
            let nextIndex = (currentIndex + 1) % difficulties.count
            let nextDifficulty = difficulties[nextIndex]
            difficultyLabel.text = nextDifficulty
            userDefaults.set(nextDifficulty, forKey: "currentDifficulty")
        }

        userDefaults.synchronize()
        changeLabel()
    }
}
