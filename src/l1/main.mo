
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import Logger "mo:ic-logger/Logger";
import BLogger "BLogger";


actor {
  let n = 100;
  //var total : Nat = 0;

  type Stats = {
        page_size: Nat;
        page: Nat;
        count: Nat;
        offset: Nat;
        //total: [Nat];
    };

    // count = PAGE_SIZE * (page - 1) + offset
    var PAGE_SIZE : Nat = 100;
    var page : Nat = 0; // total logger instances count
    var count : Nat = 0; // total log count
    var offset : Nat = 0; // index in current page
   // var total : [Nat] = [0];


  var loggers : Buffer.Buffer<BLogger.TextLogger> = Buffer.Buffer<BLogger.TextLogger>(0);


  public func view(f : Nat, t : Nat) : async [Text] {
        var result : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

        //assert(f >= 0 and f <= t and t + 1 <= count);

        if(count > 0) {
            let from = f / PAGE_SIZE;
            Debug.print("start from page:" # Nat.toText(from));
            let to = t / PAGE_SIZE;
            Debug.print("end with page:" # Nat.toText(to));

            for (i in Iter.range(from, to)) {
                Debug.print("process page:" # Nat.toText(i));
                var logger = loggers.get(i);

                let l_from = switch (i == from) {
                    case (true) { f - from * PAGE_SIZE };
                    case (false) { 0 };
                };

                let l_to = switch (i == to) {
                    case (true) { t - to * PAGE_SIZE };
                    case (false) { PAGE_SIZE - 1 };
                };

                var v : Logger.View<Text> = await logger.view(l_from, l_to);

                if(v.messages.size() > 0) {
                    for(j in Iter.range(0, v.messages.size() - 1)) {
                        Debug.print(v.messages[j]);
                        result.add(v.messages[j]);
                    };
                };
            };
        };

        result.toArray()
  };

    func roll_over() : async () {
        if (page == 0 or offset == PAGE_SIZE) {
            let l = await BLogger.TextLogger();
            loggers.add(l);
            page := page + 1;
            offset := 0;
        };
    };

    public query func stats() : async Stats {
        {
            page;
            offset;
            count;
            page_size = PAGE_SIZE;
            //total;
        }
    };

  public func append(msgs : [Text]) : async () {
    for(msg in msgs.vals()) {
        await roll_over();
        let logger = loggers.get(page - 1);
        logger.append(Array.make(msg));
        count := count + 1;
        offset := offset + 1;
/*
        let _page = loggers.size();
        let tb = await loggers.get(loggers.size() - 1).stats();
        offset := tb.bucket_sizes;
*/
    };
  };
};
