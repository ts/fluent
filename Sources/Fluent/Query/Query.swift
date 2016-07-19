/**
    Represents an abstract database query.
*/
public class Query<T: Entity> {

    //MARK: Properties

    /**
        The type of action to perform
        on the data. Defaults to `.fetch`
    */
    public var action: Action

    /**
        An array of filters to apply
        during the query's action.
    */
    public var filters: [Filter]

    /**
        Optional data to be used during
        `.create` or `.updated` actions.
    */
    public var data: Node?

    /**
        Optionally limit the amount of
        entities affected by the action.
    */
    public var limit: Limit?

    /**
        The collection or table name upon
        which the action should be performed.
    */
    public var entity: String {
        return T.entity
    }

    /**
        An array of unions, or other entities
        that will be queried during this query's 
        execution.
    */
    public var unions: [Union]

    //MARK: Internal

    /**
        The database to which the query
        should be sent.
    */
    var database: Database

    /**
        Creates a new `Query` with the
        `Model`'s database.
    */
    public init() {
        filters = []
        action = .fetch
        database = T.database
        unions = []
    }

    /**
        Runs the query given its properties
        and current state. 
     
        Returns an array of entities.
    */
    // @discardableResult
    func run() throws -> [T] {
        var models: [T] = []

        let results = try database.driver.query(self)

        for result in results {
            var model = try T(result)
            if case .dictionary(let dict) = result {
                model.id = dict[database.driver.idKey]
            }
            models.append(model)
        }

        return models
    }

    //MARK: Fetch

    /**
        Returns the first entity retreived
        by the query.
    */
    public func first() throws -> T? {
        limit = Limit(count: 1)
        return try run().first
    }

    /**
        Returns all entities retreived
        by the query.
    */
    public func all() throws -> [T] {
        return try run()
    }

    //MARK: Create

    /**
        Attempts the create action for the supplied
        serialized data. 
     
        Returns an entity if one was created.
    */
    public func create(_ serialized: Node?) throws -> T? {
        action = .create
        data = serialized
        return try run().first
    }

    /**
        Attempts to save a supplied entity
        and updates its identifier if successful.
    */
    public func save(_ model: inout T) throws {
        let data = model.makeNode()

        if let id = model.id {
            let _ = filter(database.driver.idKey, .equals, id) // discardableResult
            try modify(data)
        } else {
            let new = try create(data)
            model.id = new?.id
        }
    }

    //MARK: Delete

    /**
        Attempts to delete all entities
        in the model's collection.
    */
    public func delete() throws {
        action = .delete
        let _ = try run() // discardableResult
    }

    /**
        Attempts to delete the supplied entity
        if its identifier is set.
    */
    public func delete(_ model: T) throws {
        guard let id = model.id else {
            return
        }
        action = .delete
        
        let filter = Filter.compare(database.driver.idKey, .equals, id)
        filters.append(filter)

       let _ = try run() // discardableResult
    }

    //MARK: Update

    /**
        Attempts to modify model's collection with
        the supplied serialized data.
    */
    public func modify(_ serialized: Node?) throws {
        action = .modify
        data = serialized
        let _ = try run() // discardableResult
    }
}

extension Query: CustomStringConvertible {
    public var description: String {
        return "\(action) \(entity), \(filters.count) filters"
    }
}