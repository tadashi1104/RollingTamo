//
//  CommonFunction.swift
//  RollingTamo
//
//  Created by 鈴木 義 on 2015/06/07.
//  Copyright (c) 2015年 Tadashi.S. All rights reserved.
//

import Foundation
import AVFoundation
import SpriteKit
import GameKit

//共通クラス
class GameCommonFunction {
    
    //AudioPlayerの設定
    func setAudioPlayer(audioFileName:String, audioFileType:String, loopCount:Int) -> AVAudioPlayer {
        //再生する音源のURLを生成.
        let titleSoundFilePath : NSString = NSBundle.mainBundle().pathForResource(audioFileName, ofType: audioFileType)!
        let titleFileURL : NSURL = NSURL(fileURLWithPath: titleSoundFilePath as String)
        //AVAudioPlayerのインスタンス化.
        var myAudioPlayer = try? AVAudioPlayer(contentsOfURL: titleFileURL)
        //myAudioPlayerの再生.
        myAudioPlayer.numberOfLoops = loopCount
        
        return myAudioPlayer
    }
    
    //SKLabelの設定
    func setSKLabel(fontName:String, color:UIColor, fontSize:CGFloat, zPosition:CGFloat, point:CGPoint) -> SKLabelNode {
        //ラベルの設定
        let label = SKLabelNode(fontNamed: fontName)
        label.fontColor = color
        label.fontSize = fontSize
        label.zPosition = zPosition
        label.position = point
        
        return label
    }
    
    //値をゲームセンターに送信
    func reportScoreToGC(leaderboardIdentifier:String, score:Int64) {
        //スコアを送信するGKScoreクラスを生成
        let myScore = GKScore(leaderboardIdentifier: leaderboardIdentifier)
        //スコアを設定
        myScore.value = score
        //スコアを送信
        GKScore.reportScores([myScore], withCompletionHandler: {(error) -> Void in
            if error != nil {
                print(error.code, terminator: "")
            }
        })
    }
    
    
    
    
}