-module(cli).
-export([start/0]).

start() ->
    Shipments = seed(),
    loop(Shipments).

seed() ->
[
 {shipment,1,125,belgrade,pending},
 {shipment,2,70,athens,in_transit},
 {shipment,3,230,podgorica,pending},
 {shipment,4,75,belgrade,delivered},
 {shipment,5,95,skopje,delivered},
 {shipment,6,200,zagreb,pending},
 {shipment,7,65,athens,delivered},
 {shipment,8,55,podgorica,in_transit},
 {shipment,9,130,zagreb,delivered},
 {shipment,10,180,belgrade,pending}
 %%{shipment,11,0,podgorica,pending} % invalid weight
].

loop(Shipments) ->
    menu(),
    Input = string:trim(io:get_line("Selection > ")),

    case Input of
        "1" ->
            view_all(Shipments),
            loop(Shipments);

        "2" ->
            filter(Shipments),
            loop(Shipments);

        "3" ->
            stats(Shipments),
            loop(Shipments);
        "4" ->
            New=dispatch(Shipments),
            io:format("From Pending to In Transit~n"),
            loop(New);

        "5" ->
            io:format("Exiting Terminal...~n"),
            ok;

        _ ->
            io:format("Invalid selection.~n"),
            loop(Shipments)
    end.

menu() ->
    io:format("~n1. View All | 2. Filter | 3. Statistics | 4. Dispatch | 5. Exit~n").

view_all([]) ->
    ok;

view_all([Head | Tail]) ->
    print_shipment(Head),
    view_all(Tail).

print_shipment({shipment,ID,W,D,Status}) ->
    io:format("ID: ~p | Weight: ~p | Dest: ~p | Status: ~p~n",[ID,W,D,Status]).

filter(Shipments) ->
    Input = io:get_line("Destination > "),
    Trim = string:trim(Input),

    case string:to_integer(Trim) of
    {error, _} ->
        Dest = list_to_atom(Trim),

        Filtered = lists:filter(fun({shipment,_,_,D,_}) ->D =:= Dest end, Shipments),

        case Filtered of
            [] ->
                io:format("No shipments found.~n");
            _ ->
                view_all(Filtered)
        end;

    {_, _} ->
        io:format("Invalid input. Destination must be city name.~n")
    end.

stats(Shipments) ->
    try
        {Weight, Delivered} =
            lists:foldl(
                fun({shipment,_,W,_,Status}, {AccW,AccD}) ->

                    case W =< 0 of
                        true -> throw(invalid_weight);
                        false -> ok
                    end,

                    case Status of
                        pending ->
                            {AccW + W, AccD};

                        delivered ->
                            {AccW, AccD + 1};

                        _ ->
                            {AccW, AccD}
                    end

                end,
                {0,0},
                Shipments
            ),

        io:format(
            "Statistics: Total Pending Weight: ~pkg | Total Delivered: ~p~n",
            [Weight, Delivered])

    catch
        invalid_weight ->
            io:format("Error: Invalid shipment weight~n")
    end.

dispatch(Shipments) ->
    lists:map(
        fun({shipment,ID,W,D,pending}) ->
                {shipment,ID,W,D,in_transit};

           (S) ->
                S
        end,
    Shipments).