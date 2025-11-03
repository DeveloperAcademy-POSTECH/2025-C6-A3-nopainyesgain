//
//  CollectionViewModel+Tags.swift
//  Keychy
//
//  Created by Jini on 11/3/25.
//

import SwiftUI
import FirebaseFirestore

extension CollectionViewModel {
    
    // MARK: - 태그 이름 변경
    func renameTag(uid: String, oldName: String, newName: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        //
    }
    
    // MARK: - 태그 삭제
    func deleteTag(uid: String, tagName: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        //
    }
    
}
