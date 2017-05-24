//
//  Progress.swift
//  Pods
//
//  Created by Chang, Hao on 19/05/2017.
//
//

import Foundation

/**
 Main API class. 
 Prog stands for Progress in order to avoid having the same class name as Foundation.Progress
 */
public final class Prog {
    static var shared: Prog = Prog()
    private init() {}
    internal var progressParents: [ProgressParent] = []
    internal var progressors: [[Progressor]] = []
    
    // MARK: - Progressors
    var builtInProgressorTypes: [String: Progressor.Type] = [
        "sync": ProgressorCollection.self,
        "color": ColorProgressorView.self,
        "blur": BlurProgressorView.self,
        "activityIndicator": ActivityIndicatorProgressorView.self,
        "bar": BarProgressorView.self,
        "ring": RingProgressorView.self,
        "label": LabelProgressorView.self
    ]
    var customeProgressorTypes: [String: Progressor.Type] = [:]
    
    // MARK: - Data
    /**
     Check if the item is currently in progress
     
     - parameter parent: ProgressParent
     */
    public static func `is`(in parent: ProgressParent) -> Bool {
        return shared.progressParents.contains { $0 === parent }
    }
    
    /**
     Get all the progressor views in parent
     
     - parameter parent: ProgressParent
     */
    public static func progressors(of parent: ProgressParent) -> [Progressor] {
        guard let index = shared.progressParents.index(where: {$0 === parent}),
            index < shared.progressors.count else { return [] }
        return shared.progressors[index]
    }
    
    /**
     Register custom progressor view with identifier
     
     - parameter progressorType: progressor view type
     - parameter identifier: unique identifier for each progressor type
     */
    public static func register(progressor progressorType: Progressor.Type, withIdentifier identifier: String) {
        shared.customeProgressorTypes[identifier] = progressorType
    }
    
    // MARK: - START
    /**
     Start progress in progress parent
     
     - parameter parent: progress parent to start progress in
     - parameter types: arbitrary number of progressor types
     - parameter completion: callback function after all the starting animation
     */
    public static func start(in parent: ProgressParent, _ types: ProgressorType..., completion: @escaping (()->Void) = {}) {
        start(in: parent, types: types, completion: completion)
    }
    
    /**
     Start progress in progress parent
     
     - parameter parent: progress parent to start progress in
     - parameter types: arbitrary number of progressor types
     - parameter completion: callback function after all the starting animation
     */
    public static func start(in parent: ProgressParent, types: [ProgressorType], completion: @escaping (()->Void) = {}) {
        guard !shared.progressParents.contains(where: { $0 === parent}) else {
            print("\(parent) is already in progress")
            return
        }
        shared.progressParents.append(parent)
        shared.progressors.append([])
        
        recursiveStart(in: parent, remainingTypes: types) {
            completion()
        }
    }
    
    static func recursiveStart(in parent: ProgressParent, remainingTypes: [ProgressorType], completion: @escaping (()->Void)) {
        if let type = remainingTypes.first {
            start(in: parent, type: type) {
                var remain = remainingTypes
                remain.remove(at: 0)
                recursiveStart(in: parent, remainingTypes: remain, completion: completion)
            }
        } else {
            completion()
        }
    }
    
    static func start(in parent: ProgressParent, type: ProgressorType, completion: @escaping (()->Void)) {
        guard let index = shared.progressParents.index(where: {$0 === parent}),
            index < shared.progressors.count else { return }
        
        let progressor = shared.progressor(with: type)
        shared.progressors[index].append(progressor)
        progressor.prepareForProgress(parameter: type.parameter)
        parent.add(progressorViews: progressor.views) {
            progressor.startProgress(parameter: type.parameter, completion: completion)
        }
        
    }
    
    // MARK: - UPDATE
    /**
     Update progress in progress parent
     
     - parameter progress: completion percentage (suggested to be ranging from 0 to 1)
     - parameter parent: progress parent to update progress
     */
    public static func update(_ progress: Float, in parent: ProgressParent) {
        guard shared.progressParents.contains(where: { $0 === parent}) else {
            print("\(parent) is not in progress, use Progress.start(in:type:) instead.")
            return
        }
        
        for progressor in progressors(of: parent) {
            progressor.update(progress: progress)
        }
    }
    
    // MARK: - END
    /**
     End progress in progress parent
     
     - parameter parent: progress parent to end progress
     - parameter completion: callback function after all the ending animation
     */
    public static func end(in parent: ProgressParent, completion: @escaping (()->Void) = {}) {
        recursiveEnd(in: parent, remainingProgressors: progressors(of: parent).reversed()) { 
            if let index = shared.progressParents.index(where: { $0 === parent}) {
                shared.progressParents.remove(at: index)
                shared.progressors.remove(at: index)
            }
            completion()
        }
    }
    
    static func recursiveEnd(in parent: ProgressParent, remainingProgressors: [Progressor], completion: @escaping (()->Void)) {
        if let progressor = remainingProgressors.first {
            progressor.endProgress() {
                parent.remove(progressorViews: progressor.views) {
                    var remain = remainingProgressors
                    remain.remove(at: 0)
                    recursiveEnd(in: parent, remainingProgressors: remain, completion: completion)
                }
            }
        } else {
            completion()
        }
    }
    
}
