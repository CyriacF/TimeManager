echo "Ajout de données de test..."

curl --location 'http://localhost:4000/auth/register' \
--header 'Content-Type: application/json' \
--data '{
    "user": {
      "email": "admin@epitech.eu",
      "password": "adminadminadmin",
      "username": "Admin User",
      "is_manager":true,
      "is_director":true
  }
}'

printf "\n\n\n"
# Demande du token JWT
read -p "Veuillez entrer votre token JWT: " JWT_TOKEN

# Function to create a user
create_user() {
  curl --location 'http://localhost:4000/auth/register' \
  --header 'Content-Type: application/json' \
  --data-raw "$1"
}

# Function to create a team
create_team() {
  curl --location 'http://localhost:4000/api/teams' \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $JWT_TOKEN" \
  --data "$1"
}

# Function to update a user
update_user() {
  curl --location --request PUT "http://localhost:4000/api/users/$1" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $JWT_TOKEN" \
  --data "$2"
}

# Function to create a clock
create_clock() {
  curl --location --request POST "http://localhost:4000/api/clocks/$1" \
  --header "Authorization: Bearer $JWT_TOKEN"
}

# Function to create a task
create_task() {
  curl --location "http://localhost:4000/api/tasks/$1" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $JWT_TOKEN" \
  --data "$2"
}

# Function to create working time
create_working_time() {
  curl --location "http://localhost:4000/api/workingtime/$1" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $JWT_TOKEN" \
  --data "$2"
}
# Create users
printf "\n\n\n"
echo "Création des utilisateurs..."
create_user '{
  "user": {
      "email": "Jeandupont@epitech.eu",
      "password": "useruseruser",
      "username": "Jean dupont",
      "is_manager":true
  }
}'
create_user '{
  "user": {
    "email": "JohnDoe@epitech.eu",
    "password": "useruseruser",
    "username": "John Doe",
    "is_manager":true
  }
}'
create_user '{
  "user": {
    "email": "AliceSmith@epitech.eu",
    "password": "useruseruser",
    "username": "Alice Smith",
    "is_manager":false
  }
}'
create_user '{
  "user": {
    "email": "BobJohnson@epitech.eu",
    "password": "useruseruser",
    "username": "Bob Johnson",
    "is_manager":false
  }
}'
create_user '{
  "user": {
    "email": "MikeTomson@epitech.eu",
    "password": "useruseruser",
    "username": "Mike Tomson",
    "is_manager":false
  }
}'
create_user '{
  "user": {
    "email": "JaneDoe@epitech.eu",
    "password": "useruseruser",
    "username": "Jahn Doe",
    "is_manager":false
  }
}'

printf "\n\n\n"
# Create teams
echo "Création des équipes..."
create_team '{
  "team": {
    "manager_id": 1,
    "name": "Team Alpha"
  }
}'
create_team '{
  "team": {
    "manager_id": 3,
    "name": "Team Beta"
  }
}'

printf "\n\n\n"
# Update users to add them to teams
echo "Mise à jour des utilisateurs pour ajouter des équipes..."
update_user 1 '{
  "user": {
    "team_id": 1
  }
}'
update_user 3 '{
  "user": {
    "team_id": 2
  }
}'
update_user 4 '{
  "user": {
    "team_id": 2
  }
}'
update_user 5 '{
  "user": {
    "team_id": 2
  }
}'
update_user 6 '{
  "user": {
    "team_id": 1
  }
}'

printf "\n\n\n"
# Create clocks
echo "Ajout des horloges pour les utilisateurs..."
create_clock 1
create_clock 2
create_clock 3
create_clock 4
create_clock 5
create_clock 6
create_clock 7

printf "\n\n\n"
# Create tasks
echo "Ajout des tâches pour les utilisateurs..."
create_task 1 '{
  "task": {
    "title": "Finish report",
    "description": "Complete the quarterly report by end of day.",
    "status": "In Progress"
  }
}'
create_task 2 '{
  "task": {
    "title": "Prepare presentation",
    "description": "Prepare the presentation for the next meeting.",
    "status": "Not Started"
  }
}'
create_task 3 '{
  "task": {
    "title": "Code review",
    "description": "Review the code for the new feature.",
    "status": "In Progress"
  }
}'
create_task 4 '{
  "task": {
    "title": "Write documentation",
    "description": "Write the documentation for the new API.",
    "status": "Completed"
  }
}'
create_task 5 '{
  "task": {
    "title": "Update website",
    "description": "Update the website with the new design.",
    "status": "Not Started"
  }
}'
create_task 6 '{
  "task": {
    "title": "Test new feature",
    "description": "Test the new feature before release.",
    "status": "Completed"
  }
}'
create_task 7 '{
  "task": {
    "title": "Create new feature",
    "description": "Create a new feature for the application.",
    "status": "In Progress"
  }
}'
create_task 8 '{
  "task": {
    "title": "Fix bugs",
    "description": "Fix the bugs in the application.",
    "status": "Not Started"
  }
}'
create_task 9 '{
  "task": {
    "title": "Deploy application",
    "description": "Deploy the application to production.",
    "status": "Completed"
  }
}'

printf "\n\n\n"
# Ajout des clocks avec état
echo "Ajout des clocks avec état..."
add_clock_with_state() {
  curl -X POST "http://localhost:4000/api/clocks_with_state" \
    -H "Content-Type: application/json" \
    --header "Authorization: Bearer $JWT_TOKEN" \
    -d '{
      "user_id": "'$1'",
      "time": "'$2'",
      "status": '$3'
    }'
}

add_clock_with_state 1 "2023-01-01T08:00:00Z" true
add_clock_with_state 1 "2023-01-01T09:00:00Z" false
add_clock_with_state 2 "2023-01-01T09:00:00Z" false
add_clock_with_state 3 "2023-01-01T10:00:00Z" true
add_clock_with_state 4 "2023-01-01T11:00:00Z" false

printf "\n\n\n"
# Ajout des clocks avec état pour le mois de septembre 2024
echo "Ajout des clocks avec état pour le mois de septembre 2024..."

# Fonction pour ajouter des clocks avec état
add_clock_with_state() {
  curl -X POST "http://localhost:4000/api/clocks_with_state" \
    -H "Content-Type: application/json" \
    --header "Authorization: Bearer $JWT_TOKEN" \
    -d '{
      "user_id": "'$1'",
      "time": "'$2'",
      "status": '$3'
    }'
}

# Ajout des clocks pour chaque utilisateur
for user_id in {1..4}; do
  for day in {1..30}; do
    start_time="2024-09-$(printf "%02d" $day)T08:15:00Z"
    end_time="2024-09-$(printf "%02d" $day)T17:45:00Z"
    
    add_clock_with_state $user_id "$start_time" true
    add_clock_with_state $user_id "$end_time" false
  done
done

printf "\n\n\n"
# Create working times for the month of September 2024
echo "Ajout des temps de travail pour les utilisateurs pour le mois de septembre 2024..."

# Fonction pour ajouter des working times
create_working_time() {
  curl -X POST "http://localhost:4000/api/workingtime/$1" \
    -H "Content-Type: application/json" \
    --header "Authorization: Bearer $JWT_TOKEN" \
    -d '{
            "working_time": {
                "start": "'$2'",
                "end": "'$3'"
            }
        }'
}

# Ajout des working times pour chaque utilisateur
for user_id in {1..4}; do
  for day in {1..30}; do
    start_time="2024-09-$(printf "%02d" $day)T08:15:00Z"
    end_time="2024-09-$(printf "%02d" $day)T17:45:00Z"
    
    create_working_time $user_id "$start_time" "$end_time"
  done
done

create_working_time() {
  curl --location "http://localhost:4000/api/workingtime/$1" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $JWT_TOKEN" \
  --data "$2"
}
# Create working times
# Correct date calculation for start and end times
printf "\n\n\n"
echo "Ajout des temps de travail pour les utilisateurs..."

OS=$(uname)
if [ "$OS" = "Darwin" ]; then
  # macOS
  date_cmd() {
    date -v +${1}d +"%Y-%m-%dT08:00:00Z"
  }
else
  # Linux
  date_cmd() {
    date -d "$1 days" +"%Y-%m-%dT08:00:00Z"
  }
fi

for user_id in {1..4}; do
  for i in {0..30}; do
    start_date=$(date_cmd $i)
    end_date=$(date_cmd $i | sed 's/T08:00:00Z/T17:00:00Z/')

    create_working_time $user_id "{
      \"working_time\": {
        \"start\": \"$start_date\",
        \"end\": \"$end_date\"
      }
    }"
  done
done

printf "\n\n\n"
# Add night shifts for users
echo "Ajout des horaires de nuit pour les utilisateurs..."

# Function to add night shifts
add_night_shift() {
  local user_id=$1
  local start_time=$2
  local end_time=$3

  create_working_time $user_id "{
    \"working_time\": {
      \"start\": \"$start_time\",
      \"end\": \"$end_time\"
    }
  }"
}

# Example night shifts for users
add_night_shift 1 "2024-10-28T22:00:00Z" "2024-10-28T06:00:00Z"
add_night_shift 2 "2024-10-28T22:00:00Z" "2024-10-28T06:00:00Z"
add_night_shift 3 "2024-10-28T22:00:00Z" "2024-10-28T06:00:00Z"
add_night_shift 4 "2024-10-29T22:00:00Z" "2024-10-29T06:00:00Z"