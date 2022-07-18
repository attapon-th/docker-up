# Configuration 
 * Docker
 * Docker Compose
 * Docker stack
 * K8S


##  Requirement Tools

- [**Taskfile**](https://taskfile.dev/) Task is a task runner / build tool that aims to be simpler and easier to use than, for example, GNU Make. [Install Documentation](https://taskfile.dev/installation/)  
    Install with `go install`  
    ```shell
    go install github.com/go-task/task/v3/cmd/task@latest
    
    # example init file
    task --init  #output file: `Taskfile.yaml`
    ```
- [**Go-Sed**](https://github.com/rwtodd/Go.Sed) - สำหรับ replace file with regex(`sed` in linux)  
    ```shell
    go install github.com/rwtodd/Go.Sed/cmd/sed-go@latest
    
    # example 
    sed-go -e 's/(GREETING:) *.*/Test Test/'  < Taskfile.yaml > test.yaml   
    ```

## API Gatewal
  

- [x] [Traefik Proxy](./traefik/) - สำหรับทำ reverse proxy เหมาะใช้กับ Docker