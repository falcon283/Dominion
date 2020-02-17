<p align="center">
<img align="center" src="Dominion-logo.png" width=180px alt="Dominion" title="Dominion" />
</p>

Dominion
================

A Resource Centric framework to retrieve and receive update about any kind of resources (Network - DB - Anything Else) 

## Description

The primary goal of Dominion is to standardize the way an application handle its resources hiding the source or retrieval mechanism 
and make it fully type safe to avoid as most as possible programmer error.
Ideally on the application layer a resource is a simple peace of information and something like location or storage should be merely 
considered as implementation detail.
A `Resource` could be local or remote, could be transient or persisted, all of this should be mostrly ignored. The application layer 
should simply focus as much as possible on the business logic.

**Note: At moment only Network resources are implemented** 

Being fully protocol oriented Dominion could be easily extended supporting different kind of Providers like DiskCache Provider, DB Provider, 
CoreData or Realm Provider and virtually anything else.

## Core Concept

### Resource

A `Resource` is the core concept of Dominion. It represent the access point for the requested peace of information. A `Resource` is a
generic reference that wraps a specific type. Once initialized the Resource is fully opaque. As visible from the `Resource` interface, 
it's only possible to observe what is inside the resource, and future updates, and request a hard refresh if needed.

When you initialize a `Resource` a configuration object define it's behaviour while a provider is an object that use the configuration to 
proved the wrapped resource entity.

### ResourceConfiguration

A `ResourceConfiguration` is a protocol that define how an entity, wrapped in a `Resource` can be retrieved. It works paired to a 
`ResourceProvider` able to fullfill the same type of `Request`.
The `ResourceConfiguration` comes with two associated types: 
- `Request` define the type of request for the entity retrieval.
- `Downstream` define the type of the entity wrapped by the `Resource`

### ResourceProvider

A `ResourceProvider` is a protocol that simply allow an object retrieval. It has an associated type `Request` that is the type of request 
the provider is able to fullfill.

### ResourceService

A `ResourceService` instance serve as resources tracker. It's responsability is to keep track of resources and make it available for future 
retrieval so that multiple application module can retrieve the same resource and see the underlaing entity if it's still valid. 

# Network Implementation

At this stage Dominion is able to retrieve a Codable remote resource out of the box. `URLSession` implements `HTTPTransport` that is passed as input in `HTTPDataProvider` initializer. `URLSession` could be replaced by Alamofire implementing the `task` function of the `HTTPDataProvider` on Alamofire.

`HTTPDataProvider.Request` is a standard `URLRequest` that will be used internally and passed to `HTTPTransport` to execute the request.


## Basic Usage

1. Have your Codable object
2. Create the provider and Service, you will use them across your app
3. Create a configuration for a specific Response and retrieve the resource from the service.
4. Observe the Response. 

```
// 1.
struct User: Codable {
    let name: String
}

// 2.
let provider = HTTPDataProvider(with: URLSession.shared)
let service = ResourceService(provider: provider)

// 3.
let configuration = URLRequestConfiguration<User, Error>(route: URL(string: "https://myresource.com/user")!)
let resource = service.getResource(for: configuration)

// 4.
resource.observe { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error)
    }
}
```

## Installing (TBD)

## Authors

* **Gabriele Trabucco**

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
