let read_whole_chan chan =
  let buf = Buffer.create 4096 in
  let rec loop () =
    let line = input_line chan in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n';
      loop ()
  in
    try loop () with
      End_of_file -> Buffer.contents buf

let read_whole_file filename =
  let chan = open_in filename in
    read_whole_chan chan

let instructions_iter instructions i =
  let len = String.length instructions in
  let c = instructions.[i] in
  let j = (i + 1) mod len in
  c, j
;;

type node = {
    id : string;
    next : (node option) lazy_t * (node option) lazy_t;
};;

let process_line line : string * (string * string) =
    match String.split_on_char ' ' line with
      | id :: _ :: left :: right :: [] ->
        id, (String.sub left 1 3, String.sub right 0 3)
      | _ ->
        raise (Failure "Invalid string")
;;

let process_nodes nodes : node option =
  let rec find_next lines id : node option =
    match lines with
    | [] -> None
    | line :: rest ->
      if String.length line = 0 then
        find_next rest id
      else begin
        let (this, (left, right)) = process_line line in
        if this = id then
          Some {
            id = this;
            next = (lazy (find_next nodes left), lazy (find_next nodes right))
          }
        else
          find_next rest id
      end
  in
  find_next nodes "AAA"
;;

let process_nodes2 nodes : node list =
  let rec find_next lines id : node option =
    match lines with
    | [] -> None
    | line :: rest ->
      if String.length line = 0 then
        find_next rest id
      else begin
        let (this, (left, right)) = process_line line in
        if this = id then
          Some {
            id = this;
            next = (lazy (find_next nodes left), lazy (find_next nodes right))
          }
        else
          find_next rest id
      end
  in
  let rec find_start lines id acc : node list =
    match lines with
    | [] -> acc
    | line :: rest ->
      if String.length line = 0 then
        find_start rest id acc
      else begin
        let (this, (left, right)) = process_line line in
        let acc = if this.[2] = id then
          {
            id = this;
            next = (lazy (find_next nodes left), lazy (find_next nodes right))
          } :: acc
        else
          acc
        in
        find_start rest id acc
      end
  in
  find_start nodes 'A' []
;;

let part1 lines : int =
  let (instructions, graph, iter) = match lines with
  | instructions :: _ :: nodes ->
    let iter = instructions_iter instructions 0 in
    let graph = process_nodes nodes in
    (instructions, graph, iter)
  | _ -> raise (Failure "Invalid input")
  in
  let rec walk graph iter acc =
    let (c, iter) = iter in
    match graph.id with
    | "ZZZ" -> acc
    | _ -> match c with
      | 'L' -> (
        let next = Lazy.force @@ fst graph.next in
        match next with
        | Some node -> acc + 1 |> walk node @@ instructions_iter instructions iter
        | None -> raise (Failure "Invalid input"))
      | 'R' -> (
        let next = Lazy.force @@ snd graph.next in
        match next with
        | Some node -> acc + 1 |> walk node @@ instructions_iter instructions iter
        | None -> raise (Failure "Invalid input"))
      | _ -> raise (Failure "Invalid input")
  in
  match graph with
  | None -> raise (Failure "Invalid input")
  | Some graph -> walk graph iter 0
;;

let part2 lines : int =
  let (instructions, graphs, iter) = match lines with
  | instructions :: _ :: nodes ->
    let iter = instructions_iter instructions 0 in
    let graphs = process_nodes2 nodes in
    (instructions, graphs, iter)
  | _ -> raise (Failure "Invalid input")
  in
  let rec walk graphs iter acc =
    let (c, iter) = iter in
    let finished = List.for_all (fun (node) -> match node.id.[2] with
        | 'Z' -> true
        | _ -> false
      ) graphs in
    match finished with
    | true -> acc
    | false ->
      let graphs = List.map (fun (node) -> match c with
        | 'L' -> Option.get @@ Lazy.force @@ fst node.next
        | 'R' -> Option.get @@ Lazy.force @@ snd node.next
        | _ -> raise (Failure "Invalid input")
      ) graphs in
      acc + 1 |> walk graphs @@ instructions_iter instructions iter
  in
  walk graphs iter 0
;;

let () =
  let filename = Sys.argv.(2) in
  let part = int_of_string Sys.argv.(1) in
  let lines = read_whole_file filename
              |> String.split_on_char '\n' in
  match part with
  | 1 -> print_endline @@ "Part 1:\t" ^ string_of_int @@ part1 lines;
  | 2 -> print_endline @@ "Part 2:\t" ^ string_of_int @@ part2 lines;
  | _ -> ()
;;
