public struct Union {
    let local: Entity.Type
    let foreign: Entity.Type

    let localKey: String
    let foreignKey: String

    init(
        local: Entity.Type,
        foreign: Entity.Type,
        idKey: String,
        localKey: String? = nil,
        foreignKey: String? = nil
    ) {
        self.local = local
        self.foreign = foreign
        self.localKey = localKey ?? "\(foreign.name)_\(idKey)"
        self.foreignKey = foreignKey ?? idKey
    }
}

public final class Pivot<
    First: Entity,
    Second: Entity
>: Entity {
    public static var entity: String {
        return "\(left.name)_\(right.name)"
    }

    public static var left: Entity.Type {
        if First.entity < Second.entity {
            return First.self
        } else {
            return Second.self
        }
    }

    public static var right: Entity.Type {
        if First.entity < Second.entity {
            return Second.self
        } else {
            return First.self
        }
    }

    public var id: Node?
    public var leftId: Node?
    public var rightId: Node?

    public init(_ first: Entity, _ second: Entity) {
        if First.self == self.dynamicType.left {
            self.leftId = first.id
            self.rightId = second.id
        } else {
            self.leftId = second.id
            self.rightId = first.id
        }
    }

    public init(with node: Node, in context: Context) throws {
        id = try node.extract("id")

        let firstQ = try First.query()
        let secondQ = try Second.query()

        let firstKey = "\(First.name)_\(firstQ.idKey)"
        let secondKey = "\(Second.name)_\(secondQ.idKey)"

        if First.self == self.dynamicType.left {
            leftId = try node.extract(firstKey)
            rightId = try node.extract(secondKey)
        } else {
            leftId = try node.extract(secondKey)
            rightId = try node.extract(firstKey)
        }
    }

    public func makeNode() throws -> Node {
        return try Node([
            "id": id,
            "\(self.dynamicType.left.name)_id": leftId,
            "\(self.dynamicType.right.name)_id": rightId,
        ])
    }

    public static func prepare(_ database: Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.int("\(left.name)_id")
            builder.int("\(right.name)_id")
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
}

extension QueryRepresentable {
    @discardableResult
    public func union<Sibling: Entity>(
        _ sibling: Sibling.Type
    ) throws -> Query<Self.T> {
        let query = try makeQuery()

        let union = Union(
            local: T.self,
            foreign: sibling,
            idKey: query.database.driver.idKey,
            localKey: nil,
            foreignKey: nil
        )

        query.unions.append(union)
        return query
    }

    @discardableResult
    public func union<Sibling: Entity>(
        _ sibling: Sibling.Type,
        foreignKey: String
    ) throws -> Query<Self.T> {
        let query = try makeQuery()

        let union = Union(
            local: T.self,
            foreign: sibling,
            idKey: query.database.driver.idKey,
            localKey: nil,
            foreignKey: foreignKey
        )

        query.unions.append(union)
        return query
    }

    @discardableResult
    public func union<Sibling: Entity>(
        _ sibling: Sibling.Type,
        localKey: String
    ) throws -> Query<Self.T> {
        let query = try makeQuery()

        let union = Union(
            local: T.self,
            foreign: sibling,
            idKey: query.database.driver.idKey,
            localKey: localKey,
            foreignKey: nil
        )

        query.unions.append(union)
        return query
    }

    @discardableResult
    public func union<Sibling: Entity>(
        _ sibling: Sibling.Type,
        localKey: String,
        foreignKey: String
    ) throws -> Query<Self.T> {
        let query = try makeQuery()

        let union = Union(
            local: T.self,
            foreign: sibling,
            idKey: query.database.driver.idKey,
            localKey: localKey,
            foreignKey: foreignKey
        )

        query.unions.append(union)

        return query
    }
}
