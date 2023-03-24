import Hash "mo:base/Hash";
import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat "mo:base-ext/Nat";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Principal "mo:base-ext/Principal";


module {

  public type Interval = Nat;
  public type Task = shared() -> ();
  public type Schedule = Nat.Map<[Task]>;
  public type Increments = Nat.Map<Principal.Set>;
  public type Registry = Principal.Map<Schedule>;

  public type CyclesReport = {
    balance : Nat;
    transfer : shared () -> async ();
  };

  public type ChainReport = {
    #report : CyclesReport;
    #ping;
  };

  public type ChildService = actor {
    chain_report : shared (ChainReport) -> ();
  };

  public type HeartbeatService = actor {
    schedule : shared ([ScheduledTask]) -> async ();
    report_balance : shared (CyclesReport) -> ();
  };

  public type ScheduledTask = {
    interval : Interval;
    tasks : [Task];
  };

  public func schedule_tasks( tasks : [Task], interval : Interval ) : ScheduledTask {{
    interval = interval;
    tasks = tasks;
  }};

  public module Intervals = {

    public let _02beats : Interval = 02;
    public let _05beats : Interval = 05;
    public let _10beats : Interval = 10;
    public let _15beats : Interval = 15;
    public let _30beats : Interval = 30;
    public let _45beats : Interval = 45;
    public let _60beats : Interval = 60;
    public let _02rounds : Interval = 120;
    public let _05rounds : Interval = 540;
    public let _10rounds : Interval = 1080;
    public let _15rounds : Interval = 1620;
    public let _30rounds : Interval = 3240;
    public let _45rounds : Interval = 4860;
    public let _60rounds : Interval = 6480;
    public let _02cycles : Interval = 12960;
    public let _04cycles : Interval = 25920;
    public let _08cycles : Interval = 51840;
    public let _12cycles : Interval = 77760;
    public let _24cycles : Interval = 155520;
    
  };

  // public module Interval = {
    
  //   public func hash( x : Interval ) : Hash.Hash {Int.hash(x)};
  //   public func equal( x : Interval, y : Interval ) : Bool {Nat.Base.equal(x,y)};
  //   public func rem( x : Interval, y : Interval ) : Int {Nat.Base.rem(x, y)};

  // };

  public module Schedule = {
    
    public func init() : Schedule { Nat.Map.init<[Task]>() };

    public func entries( map : Schedule ) : Iter.Iter<(Interval,[Task])> { Nat.Map.entries(map) };

    public func intervals( map : Schedule ) : Iter.Iter<Interval> { Nat.Map.keys<[Task]>( map ) };
  
    public func schedule_task(map : Schedule, sched : ScheduledTask ) : () {
      let tasks = Buffer.fromArray<Task>( Option.get(Nat.Map.get(map, sched.interval), []) );
      tasks.append( Buffer.fromArray( sched.tasks ) );
      Nat.Map.set(map, sched.interval, Buffer.toArray( tasks ) );
    };

    public func tasks_by_interval( map : Schedule, x : Interval ) : Iter.Iter<Task> {
      Iter.fromArray<Task>( Option.get( Nat.Map.get(map, x), [] ) );
    };

  };

  public module Registry = {

    public func init() : Registry { Principal.Map.init<Schedule>() };

    public func put(map : Registry, svc : Principal, sched : Schedule ) : () { Principal.Map.set<Schedule>(map, svc, sched) };

    public func get(map : Registry, svc : Principal ) : ?Schedule { Principal.Map.get<Schedule>(map, svc) };

    public func delete(map : Registry, svc : Principal ) : () { Principal.Map.delete<Schedule>(map, svc) };

    public func tasks_by_svc_interval(map : Registry, svc : Principal, interval : Interval ) : Iter.Iter<Task> {
      switch( Principal.Map.get<Schedule>(map, svc) ){
        case ( ?sched ) Schedule.tasks_by_interval(sched, interval);
        case null object { public func next() : ?Task { null } }
      }
    }

  };

  public module Increments = {

    public func init() : Increments { Nat.Map.init<Principal.Set>() };

    public func entries( inc : Increments ) : Iter.Iter<(Interval, Principal.Set)> { Nat.Map.entries( inc ) };

    public func interval( inc : Increments ) : Iter.Iter<Interval> { Nat.Map.keys( inc ) };

    public func add(inc : Increments, interval : Interval, svc : Principal ) : () {
      let actors = Buffer.fromArray<Principal>(
        Principal.Set.toArray( Option.get( Nat.Map.get(inc, interval), Principal.Set.init() ) ) );
      actors.add( svc );
      Nat.Map.set(inc, interval, Principal.Set.fromArray( Buffer.toArray<Principal>( actors ) ) );
    };

    public func services_by_interval(inc : Increments, interval : Interval ) : Iter.Iter<Principal> {
      switch( Nat.Map.get(inc, interval) ){
        case ( ?ps ) Principal.Set.toArray( ps ).vals();
        case null object { public func next() : ?Principal { null } };
      }
    };

  };

}