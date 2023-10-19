#!/bin/bash


admin_file="admin.dat"
user_file="user.dat"
vehicle_file="vhiercel.dat"
ride_file="ride.dat"
destinations=("Tuzla" "Podorasje" "Srebrenik" "Zenica" "Sarajevo" "Husino" "Avdibasici" "Plane")


login() {
  local korisnicko_ime=$1
  local lozinka=$2
  local vrsta_korisnika=""
  read -p "Korisničko ime: " korisnicko_ime
  read -p "Lozinka: " lozinka

 
  if grep -q "^$korisnicko_ime,$lozinka$" "$admin_file"; then
    vrsta_korisnika="admin"

  elif grep -q "^$korisnicko_ime,$lozinka$" "$user_file"; then
    vrsta_korisnika="korisnik"
  else
    echo "Neispravni podaci za prijavu."
    return 1
  fi

  echo "Uspješna prijava kao ${vrsta_korisnika^}."

  if [[ "$vrsta_korisnika" == "admin" ]]; then
    admin_menu
  elif [[ "$vrsta_korisnika" == "korisnik" ]]; then
    korisnik_menu
  fi
}

admin_menu() {
  PS3="Admin izbornik - Odaberite opciju: "
  opcije=("Novi automobil" "Izmijeni automobil" "Obriši automobil" "Prikaži sve automobile" "Izlaz")
  select opcija in "${opcije[@]}"; do
    case $REPLY in
      1)
        dodaj_automobil
        ;;
      2)
        izmijeni_automobil
        ;;
      3)
        obrisi_automobil
        ;;
      4)
        prikazi_sve_automobile
        ;;
      5)
        exit
        ;;
      *)
        echo "Neispravna opcija."
        ;;
    esac
  done
}


dodaj_automobil() {
  read -p "ID TAXI-a: " id_automobila
  read -p "Proizvođač: " proizvodjac
  read -p "Model: " model
  read -p "Registarska oznaka: " registarska_oznaka
  read -p "Status (S, Z, IS): " status

  echo "$id_automobila,$proizvodjac,$model,$registarska_oznaka,$status" >> "$vehicle_file"
  echo "Automobil uspješno dodan."
  admin_menu
}

izmijeni_automobil() {
  read -p "Unesite ID automobila koji želite izmijeniti: " id_automobila

  if grep -q "^$id_automobila," "$vehicle_file"; then
    read -p "Novi proizvođač: " novi_proizvodjac
    read -p "Novi model: " novi_model
    read -p "Nova registarska oznaka: " nova_registarska_oznaka
    read -p "Novi status (S, Z, IS): " novi_status

    sed -i "s/^$id_automobila,.*/$id_automobila,$novi_proizvodjac,$novi_model,$nova_registarska_oznaka,$novi_status/" "$vehicle_file"
    echo "Detalji automobila uspješno izmijenjeni."
  else
    echo "ID automobila nije pronađen."
  fi
  admin_menu
}

obrisi_automobil() {
  if [ -f "$vehicle_file" ]; then
    echo "Svi automobili:"
    echo "---------------"

    while IFS="," read -r id_automobila proizvodjac model registarska_oznaka status || [[ -n $id_automobila ]]; do
      echo "ID automobila: $id_automobila"
      echo "Proizvođač: $proizvodjac"
      echo "Model: $model"
      echo "Registarska oznaka: $registarska_oznaka"
      echo "Status: $status"
      echo "---------------"
    done < "$vehicle_file"
  else
    echo "Nema dostupnih automobila."
  fi
  read -p "Unesite ID automobila koji želite obrisati: " id_automobila

  if grep -q "^$id_automobila," "$vehicle_file"; then
    sed -i "/^$id_automobila,/d" "$vehicle_file"
    echo "Automobil uspješno obrisan."
  else
    echo "ID automobila nije pronađen."
  fi
  admin_menu
}

prikazi_sve_automobile() {
  if [ -f "$vehicle_file" ]; then
    echo "Svi automobili:"
    echo "---------------"

    while IFS="," read -r id_automobila proizvodjac model registarska_oznaka status || [[ -n $id_automobila ]]; do
      echo "ID automobila: $id_automobila"
      echo "Proizvođač: $proizvodjac"
      echo "Model: $model"
      echo "Registarska oznaka: $registarska_oznaka"
      echo "Status: $status"
      echo "---------------"
    done < "$vehicle_file"
  else
    echo "Nema dostupnih automobila."
  fi
  if [[ "$vrsta_korisnika" == "admin" ]]; then
    admin_menu
  elif [[ "$vrsta_korisnika" == "korisnik" ]]; then
    korisnik_menu
  fi
}


korisnik_menu() {
  PS3="Korisnički izbornik - Odaberite opciju: "
  opcije=("Rezerviši vožnju" "Prikaži sve vožnje" "Izlaz")
  select opcija in "${opcije[@]}"; do
    case $REPLY in
      1)
        rezervisi_voznju
        ;;
      2)
        prikazi_sve_automobile
        ;;
      3)
        exit
        ;;
      *)
        echo "Neispravna opcija."
        ;;
    esac
  done
}


rezervisi_voznju() {
  if [ -f "$vehicle_file" ]; then
    echo "Dostupne vožnje:"
    echo "----------------"

    while IFS="," read -r id_automobila proizvodjac model registarska_oznaka status || [[ -n $id_automobila ]]; do
      echo "ID automobila: $id_automobila"
      echo "Proizvođač: $proizvodjac"
      echo "Model: $model"
      echo "Registarska oznaka: $registarska_oznaka"
      echo "Status: $status"
      echo "----------------"
    done < "$vehicle_file"

    read -p "Unesite ID automobila za rezervaciju: " rezervacija_id
    if grep -q "^$rezervacija_id," "$vehicle_file"; then
      echo "Moguće destinacije:"
      for i in "${!destinations[@]}"; do
        echo "$((i+1)). ${destinations[$i]}"
      done

      read -p "Unesite broj destinacije: " broj_destinacije
      if (( broj_destinacije >= 1 && broj_destinacije <= ${#destinations[@]} )); then
        destinacija="${destinations[$((broj_destinacije-1))]}"
        read -p "Unesite broj putnika (maksimalno 4): " broj_putnika
        if (( broj_putnika >= 1 && broj_putnika <= 4 )); then
          read -p "Unesite vrijeme dolaska (hh:mm): " vrijeme_dolaska
          echo "$rezervacija_id,$destinacija,$broj_putnika,$vrijeme_dolaska" >> "$ride_file"
          echo "Vožnja uspješno rezervisana."
          echo "Vožnja je stigla na odredište $destinacija u $vrijeme_dolaska."
        else
          echo "Neispravan broj putnika."
        fi
      else
        echo "Neispravan broj destinacije."
      fi
    else
      echo "Neispravan ID automobila."
    fi
  else
    echo "Nema dostupnih vožnji."
  fi
  korisnik_menu
}

prikazi_sve_voznje() {
  if [ -f "$vehicle_file" ]; then
    echo "Sve vožnje:"
    echo "----------"

    while IFS="," read -r id_automobila proizvodjac model registarska_oznaka status || [[ -n $id_automobila ]]; do
      echo "ID automobila: $id_automobila"
      echo "Proizvođač: $proizvodjac"
      echo "Model: $model"
      echo "Registarska oznaka: $registarska_oznaka"
      echo "Status: $status"
      echo "----------"
    done < "$vehicle_file"
  else
    echo "Nema dostupnih vožnji."
  fi
}

echo "Dobrodošli u sistem rezervacije taksija"
login
