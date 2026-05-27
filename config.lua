Config = {}


Config.debugMode = true
Config.Locale = 'en'


Config.Notify = {
  useOx = true,
  title = 'Rachet Straps'
}


Config.Commands = {
  attach = 'attach',
  detach = 'detach'
}


Config.Select = {
  radius = 5.0,                  
  includePlayerVehicle = false,  
  whitelistEnabled = true
}

Config.WhitelistedTowingVehicles = {
  `trailercar`,
  `flatbed`,
  `trflat`,
  `f450plat`,
  `carhaulsm`,
  `337flatbed`,
  `dotgooseneck`,
  `polar06seirra`,
  `boattrailer`
}


Config.Keys = {
  forward     = 172,  
  back        = 173,  
  left        = 174,  
  right       = 175,  
  up          = 10,   
  down        = 11,   
  rotateLeft  = 117,  
  rotateRight = 118,  
  finalize    = 18    
}


Config.Messages = {
  selectTowEnter      = 'Stand near your tow truck and press [ENTER] to select it.',
  selectTowNotAllowed = 'Selected vehicle is not an approved towing vehicle.',
  towSelected         = 'Towing vehicle selected. Now stand near the vehicle to tow and press [ENTER] again.',
  cannotTowSelf       = 'You cannot tow the same vehicle you selected as the tower.',
  noVehicleNearby     = 'No vehicle found nearby – move closer and press [ENTER] again.',
  vehicleLockedIn     = 'Vehicle locked in! Use arrow keys to adjust position, Page Up/Page Down to adjust height, NUMPAD 7/9 to rotate. Press [ENTER] to finalize.',
  attachedSuccess     = 'Towed vehicle attached successfully!',
  attachedFail        = 'Failed the skill check – vehicle not attached.',
  alreadyAttached     = 'You already have a vehicle attached. Use the detach option or /detach first.',
  noneAttached        = 'No vehicle is currently attached.',
  detachedSuccess     = 'Towed vehicle detached successfully!',
  healthAutoDetach    = 'Tow truck body health too low, vehicle detached!'
}

Config.TextUI = {
  enabled = true,
  position = 'top-center',
  icon = 'hook',
  instructions = '[⬆️] Forward | [⬇️] Back | [⬅️] Left | [➡️] Right | [PgUp] Up | [PgDn] Down | [NUM7/NUM9] Rotate | [Enter] Finalize',
  style = {
    borderRadius = 0,
    backgroundColor = '#121212',
    color = 'white',
    textAlign = 'center',
    padding = '10px',
    border = '2px solid #2B6CB0',
    boxShadow = '2px 2px 2px rgba(47, 255, 42, 0.8)',
    maxWidth = '500px',
    margin = '0 auto'
  }
}


Config.Placement = {
  step = 0.03,            
  rotationStep = 1.0,     
  ghostAlpha = 150,
  zeroVelEachFrame = true,
  allowRotation = true,
  freeze = true,          
  gravity = false,        
  collision = false       
}






Config.Attach = {
  collisionMode = 'none',
  useSoftPinning = false,
  isPed = false,
  vertexIndex = 2,
  fixedRot = true
}


Config.Target = {
  enabled = true,
  detachLabel = 'Detach Vehicle',
  detachIcon = 'fa-solid fa-chain-broken',
  detachDistance = 2.5
}


Config.Safety = {
  enabled = true,
  minBodyHealth = 500.0,
  checkIntervalMin = 15000,  
  checkIntervalVar = 5000    
}


Config.Detach = {
  setOnGroundProperly = true 
}
