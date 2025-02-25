import Foundation
import Models
import Network
import SwiftUI

public enum RemoteTimelineFilter: String, CaseIterable, Hashable, Equatable {
  case local, federated, trending
  
  public func localizedTitle() -> LocalizedStringKey {
    switch self {
    case .federated:
      return "timeline.federated"
    case .local:
      return "timeline.local"
    case .trending:
      return "timeline.trending"
    }
  }
  
  public func iconName() -> String {
    switch self {
    case .federated:
      return "globe.americas"
    case .local:
      return "person.2"
    case .trending:
      return "chart.line.uptrend.xyaxis"
    }
  }
}

public enum TimelineFilter: Hashable, Equatable {
  case home, local, federated, trending
  case hashtag(tag: String, accountId: String?)
  case list(list: Models.List)
  case remoteLocal(server: String, filter: RemoteTimelineFilter)
  case latest

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }

  public static func availableTimeline(client: Client) -> [TimelineFilter] {
    if !client.isAuth {
      return [.local, .federated, .trending]
    }
    return [.home, .local, .federated, .trending]
  }

  public var title: String {
    switch self {
    case .latest:
      return "Latest"
    case .federated:
      return "Federated"
    case .local:
      return "Local"
    case .trending:
      return "Trending"
    case .home:
      return "Home"
    case let .hashtag(tag, _):
      return "#\(tag)"
    case let .list(list):
      return list.title
    case let .remoteLocal(server, _):
      return server
    }
  }

  public func localizedTitle() -> LocalizedStringKey {
    switch self {
    case .latest:
      return "timeline.latest"
    case .federated:
      return "timeline.federated"
    case .local:
      return "timeline.local"
    case .trending:
      return "timeline.trending"
    case .home:
      return "timeline.home"
    case let .hashtag(tag, _):
      return "#\(tag)"
    case let .list(list):
      return LocalizedStringKey(list.title)
    case let .remoteLocal(server, _):
      return LocalizedStringKey(server)
    }
  }

  public func iconName() -> String? {
    switch self {
    case .latest:
      return "arrow.counterclockwise"
    case .federated:
      return "globe.americas"
    case .local:
      return "person.2"
    case .trending:
      return "chart.line.uptrend.xyaxis"
    case .home:
      return "house"
    case .list:
      return "list.bullet"
    case .remoteLocal:
      return "dot.radiowaves.right"
    default:
      return nil
    }
  }

  public func endpoint(sinceId: String?, maxId: String?, minId: String?, offset: Int?) -> Endpoint {
    switch self {
    case .federated: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
    case .local: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
    case let .remoteLocal(_, filter):
      switch filter {
      case .local:
        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
      case .federated:
        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
      case .trending:
        return Trends.statuses(offset: offset)
      }
    case .latest: return Timelines.home(sinceId: nil, maxId: nil, minId: nil)
    case .home: return Timelines.home(sinceId: sinceId, maxId: maxId, minId: minId)
    case .trending: return Trends.statuses(offset: offset)
    case let .list(list): return Timelines.list(listId: list.id, sinceId: sinceId, maxId: maxId, minId: minId)
    case let .hashtag(tag, accountId):
      if let accountId {
        return Accounts.statuses(id: accountId, sinceId: nil, tag: tag, onlyMedia: nil, excludeReplies: nil, pinned: nil)
      } else {
        return Timelines.hashtag(tag: tag, maxId: maxId)
      }
    }
  }
}
