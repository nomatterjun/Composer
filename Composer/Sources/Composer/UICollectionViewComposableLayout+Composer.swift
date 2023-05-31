//
//  UICollectionViewComposableLayout+Composer.swift
//  Composer
//
//  Created by 이창준 on 2023/05/31.
//

import UIKit

open class Composer<Section, Item> where Section: ComposableSection, Section: Composable, Item: ComposableItem {

  // MARK: - Properties

  private var collectionView: UICollectionView
  private var dataSource: UICollectionViewDiffableDataSource<Section, Item>
  public var configuration = Configuration(scrollDirection: .vertical)

  // MARK: - Initializer

  public init(
    collectionView: UICollectionView,
    dataSource: UICollectionViewDiffableDataSource<Section, Item>?
  ) {
    guard let dataSource else { fatalError() }
    self.collectionView = collectionView
    self.dataSource = dataSource
  }

  // MARK: - Functions

  public func adapt() {
    self.collectionView.collectionViewLayout = self.layout(configuration: self.configuration)
    self.collectionView.invalidateIntrinsicContentSize()
  }

  public typealias ElementKind = String
  public typealias DecorationItemClass = AnyClass
  public func layout(configuration: Configuration) -> UICollectionViewCompositionalLayout {
    let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()
    layoutConfiguration.scrollDirection = configuration.scrollDirection
    layoutConfiguration.interSectionSpacing = configuration.sectionSpacing
    if let header = configuration.header {
      layoutConfiguration.boundarySupplementaryItems.append(header.make())
    }
    if let footer = configuration.footer {
      layoutConfiguration.boundarySupplementaryItems.append(footer.make())
    }

    let layout = UICollectionViewCompositionalLayout(
      sectionProvider: { sectionIndex, _ in
        guard let sectionType = self.dataSource.sectionIdentifier(for: sectionIndex) else { fatalError() }

        // Item
        let item = sectionType.item.make()

        // Group
        let group = sectionType.group.make(with: item)

        // Section
        let section = sectionType.section.make(with: group)
        if
          let (sectionIdentifier, handler) = configuration.visibleItemsInvalidationHandler,
          sectionType == sectionIdentifier
        { section.visibleItemsInvalidationHandler = handler }

        return section
      },
      configuration: layoutConfiguration
    )

    if let background = configuration.background?.first {
      layout.register(background.value, forDecorationViewOfKind: background.key)
    }

    return layout
  }
}

// MARK: - Configuration

extension Composer {
  public struct Configuration {
    public var scrollDirection: UICollectionView.ScrollDirection
    public var sectionSpacing: CGFloat = .zero
    public var header: UICollectionViewComposableLayout.BoundaryItem?
    public var footer: UICollectionViewComposableLayout.BoundaryItem?
    public var background: [ElementKind: DecorationItemClass]?

    public init(
      scrollDirection: UICollectionView.ScrollDirection,
      sectionSpacing: CGFloat = .zero,
      header: UICollectionViewComposableLayout.BoundaryItem? = nil,
      footer: UICollectionViewComposableLayout.BoundaryItem? = nil,
      background: [ElementKind: DecorationItemClass]? = nil
    ) {
      self.scrollDirection = scrollDirection
      self.sectionSpacing = sectionSpacing
      self.header = header
      self.footer = footer
      self.background = background
    }

    public var visibleItemsInvalidationHandler: (
      to: Section,
      ([NSCollectionLayoutVisibleItem], CGPoint, NSCollectionLayoutEnvironment) -> Void)?
  }
}
