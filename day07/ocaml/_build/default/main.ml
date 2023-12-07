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

type hand_type =
  | FiveOfAKind of string
  | FourOfAKind of string
  | FullHouse of string
  | ThreeOfAKind of string
  | TwoPair of string
  | OnePair of string
  | HighCard of string

let hand_to_rank hand = match hand with
  | FiveOfAKind _ -> 7
  | FourOfAKind _ -> 6
  | FullHouse _ -> 5
  | ThreeOfAKind _ -> 4
  | TwoPair _ -> 3
  | OnePair _ -> 2
  | HighCard _ -> 1

let card_strength card = match card with
  | 'A' -> 13
  | 'K' -> 12
  | 'Q' -> 11
  | 'J' -> 10
  | 'T' -> 9
  | '9' -> 8
  | '8' -> 7
  | '7' -> 6
  | '6' -> 5
  | '5' -> 4
  | '4' -> 3
  | '3' -> 2
  | '2' -> 1
  | _ -> 0

let card_strength_2 card = match card with
  | 'A' -> 13
  | 'K' -> 12
  | 'Q' -> 11
  | 'J' -> 1
  | 'T' -> 10
  | '9' -> 9
  | '8' -> 8
  | '7' -> 7
  | '6' -> 6
  | '5' -> 5
  | '4' -> 4
  | '3' -> 3
  | '2' -> 2
  | _ -> 0

let hand_str hand = match hand with
  | FiveOfAKind s -> s
  | FourOfAKind s -> s
  | FullHouse s -> s
  | ThreeOfAKind s -> s
  | TwoPair s -> s
  | OnePair s -> s
  | HighCard s -> s

(*
let hand_type_str hand = match hand with
  | FiveOfAKind _ -> "FiveOfAKind"
  | FourOfAKind _ -> "FourOfAKind"
  | FullHouse _ -> "FullHouse"
  | ThreeOfAKind _ -> "ThreeOfAKind"
  | TwoPair _ -> "TwoPair"
  | OnePair _ -> "OnePair"
  | HighCard _ -> "HighCard"
*)

let cmp_cards_strength x y = card_strength y - card_strength x
let cmp_hands_strength x y =
  let x = fst x in
  let y = fst y in
  let cmp = (hand_to_rank y) - (hand_to_rank x) in
  if cmp <> 0 then cmp else begin
    let x = hand_str x in
    let y = hand_str y in
    let rec aux i =
        if i >= String.length x then 0 else begin
          let x = card_strength x.[i] in
          let y = card_strength y.[i] in
          let cmp = y - x in
          if cmp <> 0 then cmp else aux (i + 1)
        end in
    aux 0
  end
;;

let cmp_cards_strength_2 x y = card_strength_2 y - card_strength_2 x
let cmp_hands_strength_2 x y =
  let x = fst x in
  let y = fst y in
  let cmp = (hand_to_rank y) - (hand_to_rank x) in
  if cmp <> 0 then cmp else begin
    let x = hand_str x in
    let y = hand_str y in
    let rec aux i =
        if i >= String.length x then 0 else begin
          let x = card_strength_2 x.[i] in
          let y = card_strength_2 y.[i] in
          let cmp = y - x in
          if cmp <> 0 then cmp else aux (i + 1)
        end in
    aux 0
  end
;;

let str_to_chars_list str =
  let rec aux i acc =
    if i < 0 then
      acc
    else
      aux (i - 1) (str.[i] :: acc)
  in
  aux (String.length str - 1) []
;;

let chars_list_to_str chars =
  String.concat "" (List.map (String.make 1) chars)
;;

let max_reps str =
  let str = str_to_chars_list str
            |> List.sort cmp_cards_strength
            |> chars_list_to_str in
  let rec max_reps' i last max acc =
    let max = if acc > max then acc else max in
    if i >= String.length str then
      max
    else begin
      let ret = max_reps' (i + 1) (Some str.[i]) max in
      match last with
      | None -> ret 1
      | Some char -> ret (if char = str.[i] then acc + 1 else 1)
    end in
  max_reps' 0 None 0 0
;;

let hand_str_to_hand str =
  match str_to_chars_list str
      |> List.sort_uniq cmp_cards_strength
      |> List.length with
  | 1 -> FiveOfAKind str
  | 2 -> let max = max_reps str in
    if max = 4 then FourOfAKind str else FullHouse str
  | 3 -> let max = max_reps str in
    if max = 3 then ThreeOfAKind str else TwoPair str
  | 4 -> OnePair str
  | 5 -> HighCard str
  | _ -> raise (Failure "Invalid hand string")
;;

let hand_str_to_hand_2 str =
  let str_without_j = str_to_chars_list str
                      |> List.filter (fun (card) -> card <> 'J')
                      |> chars_list_to_str in
  match str_to_chars_list str_without_j
      |> List.sort_uniq cmp_cards_strength_2
      |> List.length with
  | 0 -> FiveOfAKind str
  | 1 -> FiveOfAKind str
  | 2 -> let max = max_reps str_without_j + (String.length str - String.length str_without_j) in
    if max = 4 then FourOfAKind str else FullHouse str
  | 3 -> let max = max_reps str_without_j + (String.length str - String.length str_without_j) in
    if max = 3 then ThreeOfAKind str else TwoPair str
  | 4 -> OnePair str
  | 5 -> HighCard str
  | _ -> raise (Failure "Invalid hand string")
;;

let process_hand str = match String.split_on_char ' ' str with
  | hand :: bid :: [] -> Some (hand_str_to_hand hand, int_of_string bid)
  | _ -> None

let process_hand_2 str = match String.split_on_char ' ' str with
  | hand :: bid :: [] -> Some (hand_str_to_hand_2 hand, int_of_string bid)
  | _ -> None

let part1 lines : int =
    let rec get_hands list hands = match list with
      | [] -> hands
      | x :: rest -> get_hands rest @@ match process_hand x with
        | Some hand -> hand :: hands
        | None -> hands in
    let hands = get_hands lines [] |> List.sort cmp_hands_strength in
    let rec total list counter acc = match list with
      | [] -> acc
      | x :: rest -> total rest (counter + 1) (acc + ((snd x) * counter)) in
    total (List.rev hands) 1 0
;;

let part2 lines : int =
    let rec get_hands list hands = match list with
      | [] -> hands
      | x :: rest -> get_hands rest @@ match process_hand_2 x with
        | Some hand -> hand :: hands
        | None -> hands in
    let hands = get_hands lines [] |> List.sort cmp_hands_strength_2 in
    let rec total list counter acc = match list with
      | [] -> acc
      | x :: rest -> total rest (counter + 1) (acc + ((snd x) * counter)) in
    total (List.rev hands) 1 0
;;

let () =
  let filename = Sys.argv.(1) in
  let lines = read_whole_file filename
              |> String.split_on_char '\n' in
  print_endline @@ "Part 1:\t" ^ string_of_int @@ part1 lines;
  print_endline @@ "Part 2:\t" ^ string_of_int @@ part2 lines;
;;
