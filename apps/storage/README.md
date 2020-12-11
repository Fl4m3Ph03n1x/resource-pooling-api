# Storage

Storage layer for the application. This layer is responsible for persisting
data in memory (for now) but it could be easily adapted to persist said data 
more permanently on disk. The other layers really don't care as long as the 
public API of the layer doesn't change.