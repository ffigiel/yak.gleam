pub type User {
  Anonymous
}

pub fn to_string(user: User) -> String {
  case user {
    Anonymous -> "anonymous"
  }
}
