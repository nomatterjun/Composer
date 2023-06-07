//
//  ComposableSection+Item.swift
//  Composer
//
//  Created by 이창준 on 2023/05/31.
//

@MainActor
public protocol ComposableItem: Hashable, Sendable { }

@MainActor
public protocol ComposableSection: Hashable, Sendable { }
