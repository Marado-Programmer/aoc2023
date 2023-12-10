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

let ints_of_strings strs = List.map (fun (i) -> int_of_string i) strs

let find_seqs seq =
  let rec find_seq' init seq =
    match init with
    | x :: y :: rest -> find_seq' (y :: rest) @@ (y - x) :: seq
    | _ -> List.rev seq
  in
  let rec find_seqs' seq lst =
    let new_seq = find_seq' seq [] in
    if List.for_all (fun (i) -> i = 0) new_seq then
      List.rev lst
    else
      new_seq :: lst |> find_seqs' new_seq
  in
  seq :: find_seqs' seq []

let rec last lst = match lst with
  | [] -> None
  | x :: [] -> Some x
  | _ :: rest -> last rest

let calc_next seq add = let x = last seq |> Option.get in x + add

let part1 lines : int =
  let rec aux lines acc =
    match lines with
    | [] -> acc
    | line :: rest ->
      if (String.length line = 0) then aux rest acc else begin
        let ints = ints_of_strings @@ String.split_on_char ' ' line in
        let seqs = find_seqs ints in
        let next = List.fold_right (calc_next) seqs 0 in
        print_endline @@ string_of_int next;
        acc + next |> aux rest
      end
  in
  aux lines 0
;;

let part2 lines : int =
  let rec aux lines acc =
    match lines with
    | [] -> acc
    | line :: rest ->
      if (String.length line = 0) then aux rest acc else begin
        let ints = ints_of_strings @@ String.split_on_char ' ' line in
        let seqs = List.rev ints |> find_seqs in
        let next = List.fold_right (calc_next) seqs 0 in
        print_endline @@ string_of_int next;
        acc + next |> aux rest
      end
  in
  aux lines 0
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
