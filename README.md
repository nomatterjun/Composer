# Composer

`Composer`는 `UICollectionViewCompositionalLayout`을 좀 더 간편하게 사용하고, `ViewController`의 파일 길이가 과도하게 길어지는 것을 방지하기 위해 설계되었습니다.

[![Platforms](https://img.shields.io/badge/Platforms-iOS+15.0-green?style=flat-square)](https://img.shields.io/badge/Platforms-iOS.15.0-Green?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

## Instruction

총 네 단계의 Configuration을 통해 사용할 수 있습니다.

### 1. Section & Item 정의

---

```swift
public protocol ComposableSection: Hashable { }
public protocol ComposableItem: Hashable { }
```

Section은 `Section`과 `Item`으로 구분되며 각각은 namespace 프로토콜을 준수해야 합니다.

- `ComposableSection`: `Section`
- `ComposableItem`: `Item`

#### 사용 예시

```swift
// MARK: - Item

enum HomeSectionItem: ComposableItem {
  case upcoming(Upcoming)
  case timeline(Timeline)

  enum Upcoming: Hashable {
    case empty(UIImage?, String)
    case reminder(Reminder)
  }

  enum Timeline: Hashable {
    case empty(UIImage?, String)
    case gift(Gift)
  }
}

// MARK: - Section

public enum HomeSection: ComposableSection {
  case upcoming(isEmpty: Bool)
  case timeline(isEmpty: Bool)
}
```

`Section`과 `Item` 모두 `Hashable` 프로토콜을 준수해야 합니다.

> 기본적으로 `Hashable`한 타입들만 사용한다면 에러는 발생하지 않겠지만, 코드의 직관성과 안정성을 위해 `==`와 `hash(into:)` 함수를 작성해주는 것이 좋습니다!

```swift
// MARK: - Hashable

extension HomeSection {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.upcoming, .upcoming):
      return true
    case (.timeline, .timeline):
      return true
    default:
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case .upcoming:
      hasher.combine("upcoming")
    case .timeline:
      hasher.combine("timeline")
    }
  }
}
```

### 2. Composable 프로토콜 채택

---

```swift
public protocol Composable {
  var item: UICollectionViewComposableLayout.Item { get }
  var group: UICollectionViewComposableLayout.Group { get }
  var section: UICollectionViewComposableLayout.Section { get }
}
```

```swift
// MARK: - Composer

extension HomeSection: Composable {
  // Layout Configurations
}
```

`ComposableSection` 프로토콜을 채택한 `Section`에 `Composable` 프로토콜을 추가적으로 채택하는 것으로 `UICollectionViewComposableLayout`을 사용할 수 있습니다.

총 세가지 프로퍼티(`item`, `group`, `section`)를 설정해주는 것으로 각 요소의 레이아웃을 설정해줄 수 있습니다.

각 프로퍼티들은 `UICollectionViewCompositionalLayout`의 요소들을 간편하게 설정할 수 있도록 래핑한 프로퍼티입니다.

각 프로퍼티는 다음과 같은 형태로 설정됩니다.

```swift
public var item: UICollectionViewComposableLayout.Item {
    switch self { // 1️⃣
    case .profileSetupHelper:
      return .grid( // 2️⃣
        width: .absolute(250),
        height: .absolute(250)
      )
    case .favors:
      return .grid(
        width: .estimated(50),
        height: .absolute(32)
      )
    case .anniversaries:
      return .listRow(
        height: .absolute(95)
      )
    case .memo:
      return .listRow(
        height: .estimated(130)
      )
    case .friends:
      return .grid(
        width: .absolute(60),
        height: .fractionalHeight(1.0)
      )
    }
  }
```

1. Section 별로 Layout 설정이 가능합니다. `switch`문을 사용하여 정의해주면 간편합니다.
2. 알맞는 형태의 레이아웃을 선택하는 것으로 각 `NSCollectionLayoutItem`을 간편하게 설정하거나 `.custom`을 통해 직접 설정해줄 수 있습니다.

각 `NSCollectionLayoutItem`에 제공되는 설정은 **아래**에서 확인할 수 있습니다. 프로젝트 내에서 직접 확인하고 싶을 경우 `UICollectionViewComposableLayout.swift` 파일에서 확인할 수 있습니다.

[NSCollectionLayoutItems](https://github.com/nomatterjun/Composer/wiki/NSCollectionLayoutItems)

> 📍 CollectionView 전체에 대한 Configuration은 `Composable`를 초기화할 때 해줄 수 있습니다. 아래에서 확인해주세요.

#### Section Header / Footer

각 섹션마다 Header와 Footer를 등록해주고 싶다면 `section` 프로퍼티에서 등록해줄 수 있습니다.

```swift
var section: UICollectionViewComposableLayout.Section {
  switch self {
  case .timeline:
    return .base(
      contentInsets: NSDirectionalEdgeInsets(top: .zero, leading: 20, bottom: .zero, trailing: 20),
      boundaryItems: [
        .header(height: .absolute(68)) // 👈 BoundaryItems를 사용한 헤더 등록
      ]
    )
  }
}
```

☑️ Header와 Footer는 기본적으로 `UICollectionView.elementKindSectionHeader`와  `UICollectionView.elementKindSectionFooter`를 `kind`로 갖습니다. 별도의 `kind`를 등록하고 싶다면 `kind:` 파라미터를 활용해주세요.

### 하나의 섹션에 동적인 레이아웃이 필요할 때

하나의 섹션에 여러 형태의 `Item`, `Group`, `Section` 등이 필요할 수 있습니다.

그럴 때는 `Section`의 연관값으로 형태의 구분자를 넣어주고 각 `Item`, `Group`, `Section`에서 분기처리를 통해 레이아웃을 정의해줌으로서 구현할 수 있습니다.

```swift
public enum HomeSection: ComposableSection {
  case upcoming(isEmpty: Bool) // Item이 비어있을 때의 레이아웃을 지정해주기 위한 연관값
  case timeline(isEmpty: Bool)
}
```

```swift
case .timeline(let isEmpty):
  if isEmpty { // 연관값에 따라 분기 처리
    return .base(
      contentInsets: NSDirectionalEdgeInsets(top: .zero, leading: 20, bottom: .zero, trailing: 20),
      boundaryItems: [
        .header(height: .absolute(68))
      ]
    )
  } else {
    return .base(
      spacing: 5,
      contentInsets: NSDirectionalEdgeInsets(top: .zero, leading: 20, bottom: .zero, trailing: 20),
      boundaryItems: [
        .header(
          height: .absolute(68.0 + 16.0),
          contentInsets: NSDirectionalEdgeInsets(top: .zero, leading: .zero, bottom: 16, trailing: .zero)
        ),
        .footer(height: .absolute(120))
      ]
    )
  }
```

예시의 경우 `Section` 만의 분기처리를 다루고 있지만, `Item`과 `Group`에서도 동일한 방법으로 구현이 가능합니다. 😊

### 3. Composer 정의

---

```swift
open class Composer<Section, Item> where
  Section: ComposableSection, Section: Composable,
  Item: ComposableItem {
  public init(
    collectionView: UICollectionView,
    dataSource: UICollectionViewDiffableDataSource<Section, Item>
  ) {
    self.collectionView = collectionView
    self.dataSource = dataSource
  }
}
```

`Composer`는 DataSource의 구조를 파악하기 위해 두 개의 Generic 파라미터를 필요로 합니다.

- `Section`: 1과 2에서 언급된 `ComposableSection`과 `Composable`를 채택하고 있어야 합니다.
- `Item`: 1에서 언급된 `ComposableItem`을 채택하고 있어야 합니다.

`Composer`는 생성자를 통해 적용될 대상 CollectionView와 DataSource를 주입받아 사용됩니다.

> DataSource는 `DiffableDataSources`를 사용하고 있습니다.

또한 CollectionView 전체적으로 적용되는 Configuration 또한 `Composer`에게 전달해줍니다.

```swift
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
}
```

위 Configuration 구조체를 사용하여 `UICollectionView`의 전역적인 사항들을 적용해줄 수 있습니다.

#### 사용 예시

```swift
lazy var composer: Composer<ProfileSection, ProfileSectionItem> = {
  let composer = Composer(collectionView: self.collectionView, dataSource: self.dataSource)
  let header = UICollectionViewComposableLayout.BoundaryItem.header(
    height: .estimated(128),
    kind: ProfileElementKind.collectionHeader
  )
  composer.configuration = Composer.Configuration(
    scrollDirection: .vertical,
    header: header,
    background: [
      ProfileElementKind.sectionWhiteBackground: ProfileSectionBackgroundView.self
    ]
  )
  return composer
}()
```

### 4. 적용

---

```swift
public override func viewDidLoad() {
  super.viewDidLoad()

  self.composer.compose()
}
```

`UICollectionViewComposableLayout`, `Composer`에 대한 설정이 모두 끝났다면 `composer.compose()` 메서드를 호출하여 적용해줍니다.

## Installation

### Swift Package Manager

``` Swift
dependencies: [
    .package(url: "https://github.com/nomatterjun/Composer.git", .upToNextMajor(from: "1.0.1"))
]
```
