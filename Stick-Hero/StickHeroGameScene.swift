//
//  StickHeroGameScene.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/19.
//  Copyright © 2015年 koofrank. All rights reserved.
//

import SpriteKit

class StickHeroGameScene: SKScene, SKPhysicsContactDelegate {
    var gameOver = false {
        willSet {
            if (newValue) {
                //记录分数
                isBegin = false
                isEnd = false
                score = 0
                nextLeftStartX = playAbleRect.origin.x
                removeAllChildren()
                start()
            }
            
        }
    }
    
    var isBegin = false
    var isEnd = false
    var leftStack:SKShapeNode?
    var rightStack:SKShapeNode?
    
    var nextLeftStartX:CGFloat = 0
    var stickHeight:CGFloat = 0
    
    let HeroName = "hero"
    
    var score = 0 {
        willSet {
            let scoreBand = childNodeWithName("score") as? SKLabelNode
            scoreBand?.text = "\(newValue)"
            scoreBand?.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: 0.1), SKAction.scaleTo(1, duration: 0.1)]))
            
            if (newValue == 1) {
                let tip = childNodeWithName("tip") as? SKLabelNode
                tip?.runAction(SKAction.fadeAlphaTo(0, duration: 0.4))
            }
        }
    }
    
    lazy var playAbleRect:CGRect = {
        let maxAspectRatio:CGFloat = 16.0/9.0 // iPhone 5"
        let maxAspectRatioWidth = self.size.height / maxAspectRatio
        let playableMargin = (self.size.width - maxAspectRatioWidth) / 2.0
        return CGRectMake(playableMargin, 0, maxAspectRatioWidth, self.size.height)
        }()
    
    lazy var walkAction:SKAction = {
        var textures:[SKTexture] = []
        for i in 0...1 {
            let texture = SKTexture(imageNamed: "human\(i + 1).png")
            textures.append(texture)
        }
        
        let action = SKAction.animateWithTextures(textures, timePerFrame: 0.15, resize: true, restore: true)
        
        return SKAction.repeatActionForever(action)
        }()
    
    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPointMake(0.5, 0.5)
        physicsWorld.contactDelegate = self
        nextLeftStartX = playAbleRect.origin.x
    }

    override func didMoveToView(view: SKView) {
        start()
    }
    
    func start() {
        loadBackground()
        loadScoreBackground()
        loadScore()
        loadTip()
        leftStack = loadStacks(false, startLeftPoint: nextLeftStartX)
        loadHero()
        
        let maxGap = Int(playAbleRect.width - nextLeftStartX - 300)
        let gap = CGFloat(randomInRange(80...maxGap))
        rightStack = loadStacks(false, startLeftPoint: nextLeftStartX + gap)
        
        gameOver = false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard isBegin && isEnd else {
            isBegin = true
            
            let stick = SKSpriteNode(color: SKColor.blackColor(), size: CGSizeMake(12, 1))
            stick.zPosition = 50
            stick.name = "stick"
            stick.anchorPoint = CGPointMake(0.5, 0);
            
            let hero = childNodeWithName(HeroName) as! SKSpriteNode
            stick.position = CGPointMake(hero.position.x + hero.size.width / 2 + 18, hero.position.y - hero.size.height / 2)
        
            let height = self.size.height - 400
            addChild(stick)
     
            let action = SKAction.resizeToHeight(height, duration: 1.5)
            stick.runAction(action, withKey:"stickGrow")
            
            let scaleAction = SKAction.sequence([SKAction.scaleYTo(0.9, duration: 0.05), SKAction.scaleYTo(1, duration: 0.05)])
            let loopAction = SKAction.group([SKAction.playSoundFileNamed("stick_grow_loop.wav", waitForCompletion: true)])
            stick.runAction(SKAction.repeatActionForever(loopAction), withKey: "audio_stick_loop")
            hero.runAction(SKAction.repeatActionForever(scaleAction), withKey: "audio_hero_loop")
            
            return
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if isBegin && !isEnd {
            isEnd  = true
            let hero = childNodeWithName(HeroName) as! SKSpriteNode
            hero.removeActionForKey("audio_hero_loop")
            hero.runAction(SKAction.scaleYTo(1, duration: 0.04))
            
            let stick = childNodeWithName("stick") as! SKSpriteNode
            stick.removeActionForKey("stickGrow")
            stick.removeActionForKey("audio_stick_loop")
            stick.runAction(SKAction.playSoundFileNamed("kick.wav", waitForCompletion: false), withKey: "audio_stick_kick")
            
            stickHeight = stick.size.height;
            
            let action = SKAction.rotateToAngle(CGFloat(-M_PI / 2), duration: 0.4, shortestUnitArc: true)
            let playFall = SKAction.playSoundFileNamed("fall.wav", waitForCompletion: false)
            
            stick.runAction(SKAction.sequence([SKAction.waitForDuration(0.2), action, playFall]), completion: { () -> Void in
                let rightPoint = 768 + stick.position.x + self.stickHeight
                
                guard rightPoint < self.nextLeftStartX else {
                    self.heroGo(false)
                    return
                }
                
                var i = 0
               
                for node in self.children {
                    if (node.name == "stack") {
                        if (CGRectIntersectsRect(node.frame, stick.frame)) {
                            i++;
                        }
                    }
                }
                self.heroGo(i >= 2)
            })
        }
    }
    
    func heroGo(pass:Bool) {
        let speed:CGFloat = 760
        let hero = childNodeWithName(HeroName) as! SKSpriteNode
        
        guard pass else {//失败
            let stick = childNodeWithName("stick") as! SKSpriteNode
            
            let dis:CGFloat = stick.position.x + self.stickHeight
            let disGap = nextLeftStartX - (768 - abs(hero.position.x)) - (rightStack?.frame.size.width)! / 2

            let move = SKAction.moveToX(dis, duration: NSTimeInterval(abs(disGap / speed)))

            hero.runAction(walkAction, withKey: "walk")
            hero.runAction(move, completion: {[unowned self] () -> Void in
                stick.runAction(SKAction.rotateToAngle(CGFloat(-M_PI), duration: 0.4))
                
                hero.physicsBody!.affectedByGravity = true
                hero.runAction(SKAction.playSoundFileNamed("dead.wav", waitForCompletion: false), withKey: "audio_hero_dead")
                hero.removeActionForKey("walk")
                self.runAction(SKAction.waitForDuration(2), completion: {[unowned self] () -> Void in
                    self.gameOver = true
                })
            })

            return
        }
        
        let dis:CGFloat = -768 + nextLeftStartX - hero.size.width / 2 - 20
        let disGap = nextLeftStartX - (768 - abs(hero.position.x)) - (rightStack?.frame.size.width)! / 2
        
        let move = SKAction.moveToX(dis, duration: NSTimeInterval(abs(disGap / speed)))
 
        hero.runAction(walkAction, withKey: "walk")
        hero.runAction(move) { [unowned self]() -> Void in
            self.score++
            
            hero.runAction(SKAction.playSoundFileNamed("victory.wav", waitForCompletion: false), withKey: "audio_hero_victory")
            hero.removeActionForKey("walk")
            self.moveStackAndCreateNew()
        }
    }
    
    func moveStackAndCreateNew() {
        let action = SKAction.moveBy(CGVectorMake(-nextLeftStartX + (rightStack?.frame.size.width)! + playAbleRect.origin.x - 2, 0), duration: 0.3)
        rightStack?.runAction(action)
        let hero = childNodeWithName(HeroName) as! SKSpriteNode
        let stick = childNodeWithName("stick") as! SKSpriteNode
        
        hero.runAction(action)
        stick.runAction(SKAction.group([SKAction.moveBy(CGVectorMake(-1536, 0), duration: 0.5), SKAction.fadeAlphaTo(0, duration: 0.3)])) { () -> Void in
            stick.removeFromParent()
        }

        leftStack?.runAction(SKAction.moveBy(CGVectorMake(-1536, 0), duration: 0.5), completion: {[unowned self] () -> Void in
            self.leftStack?.removeFromParent()
            
            let maxGap = Int(self.playAbleRect.width - (self.rightStack?.frame.size.width)! - 300)
            let gap = CGFloat(randomInRange(80...maxGap))
            
            self.leftStack = self.rightStack
            self.rightStack = self.loadStacks(true, startLeftPoint:self.playAbleRect.origin.x + (self.rightStack?.frame.size.width)! + gap)
        })
    }
    
    deinit {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - 加载场景
private extension StickHeroGameScene {
    func loadBackground() {
        guard let _ = childNodeWithName("background") as! SKSpriteNode? else {
            let texture = SKTexture(image: UIImage(named: "stick_background.jpg")!)
            let node = SKSpriteNode(texture: texture)
            node.size = texture.size()
            node.name = "background"
            node.zPosition = 0
            self.physicsWorld.gravity = CGVectorMake(0, -100)
            
            addChild(node)
            return
        }
    }
    
    func loadScore() {
        let scoreBand = SKLabelNode(fontNamed: "Arial")
        scoreBand.name = "score"
        scoreBand.text = "0"
        scoreBand.position = CGPointMake(0, 1024 - 200)
        scoreBand.fontColor = SKColor.whiteColor()
        scoreBand.fontSize = 100
        scoreBand.zPosition = 100
        scoreBand.horizontalAlignmentMode = .Center
        
        addChild(scoreBand)
    }
    
    func loadScoreBackground() {
        let back = SKShapeNode(rect: CGRectMake(0-120, 1024-200-30, 240, 140), cornerRadius: 20)
        back.zPosition = 50
        back.fillColor = SKColor.blackColor().colorWithAlphaComponent(0.3)
        addChild(back)
    }
    
    func loadHero() {
        let hero = SKSpriteNode(imageNamed: "human1")
        hero.name = HeroName
        hero.position = CGPointMake(-768 + nextLeftStartX - hero.size.width / 2 - 20, -1024 + 400 + hero.size.height / 2 - 4)
        hero.zPosition = 100
        hero.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(16, 18))
        hero.physicsBody?.affectedByGravity = false
        hero.physicsBody?.allowsRotation = false
        
        addChild(hero)
    }
    
    func loadTip() {
        let tip = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        tip.name = "tip"
        tip.text = "将手放在屏幕使竿变长"
        tip.position = CGPointMake(0, 1024 - 350)
        tip.fontColor = SKColor.blackColor()
        tip.fontSize = 52
        tip.zPosition = 100
        tip.horizontalAlignmentMode = .Center
    
        addChild(tip)
    }
    
    func loadStacks(animate: Bool, startLeftPoint: CGFloat) -> SKShapeNode {
        let width:CGFloat = CGFloat(randomInRange(10...30) * 10)
        let height:CGFloat = 400.0
        let stack = SKShapeNode(rectOfSize: CGSizeMake(width, height))
        stack.fillColor = SKColor.blackColor()
        stack.zPosition = 10
        stack.name = "stack"
 
        if (animate) {
            stack.position = CGPointMake(768, -1024 + height / 2)
            stack.runAction(SKAction.moveToX(-768 + width / 2 + startLeftPoint, duration: 0.3), completion: {[unowned self] () -> Void in
                self.isBegin = false
                self.isEnd = false
            })
            
        }
        else {
            stack.position = CGPointMake(-768 + width / 2 + startLeftPoint, -1024 + height / 2)
        }
        addChild(stack)
 
        nextLeftStartX = width + startLeftPoint
        
        return stack
    }
}
