//
//  UICollectionViewComposableLayout+Composable.swift
//  Composable
//
//  Created by 이창준 on 2023/05/31.
//

public protocol Composable {
  var item: UICollectionViewComposableLayout.Item { get }
  var group: UICollectionViewComposableLayout.Group { get }
  var section: UICollectionViewComposableLayout.Section { get }
}
