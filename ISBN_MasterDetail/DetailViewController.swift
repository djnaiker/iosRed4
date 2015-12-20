

import UIKit
import CoreData

class DetailViewController: UIViewController {

   

    @IBOutlet weak var codigoISBN: UITextField!
    @IBOutlet weak var indicadorActividad: UIActivityIndicatorView!
    @IBOutlet weak var etiquetaNombreLibro: UILabel!
    @IBOutlet weak var etiquetaAutores: UILabel!
    @IBOutlet weak var imagenPortada: UIImageView!

    @IBAction func codigoISBN(sender: AnyObject) {
        buscaCodigo(self.codigoISBN.text!)
    }
    
    
    var opcion = 0
    var libroBuscado = ""
    
    var codigoError = 0
    var texto = ""
    var tituloLibro = ""
    var autores = ""
    var urlPortada = ""
    var libroYaBuscado = false
    
    
    var contexto : NSManagedObjectContext? = nil
    
    func borraTodo(){
        self.etiquetaAutores.text = ""
        self.etiquetaNombreLibro.text = ""
        self.imagenPortada.image = nil
    }
    
    func buscaCodigo(codigoBuscado: String){
        self.codigoError = 0
        self.tituloLibro = ""
        self.autores = ""
        self.urlPortada = ""
        borraTodo()
        if codigoBuscado == "" {
            let alerta = UIAlertController(title: "Faltan datos", message: "Falta el dato del libro para buscar", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
            }))
            self.presentViewController(alerta, animated: true, completion: nil)
        } else {
            self.indicadorActividad.startAnimating()
            obtenerTextoISBN2(codigoBuscado)
        }
    }
    
    func obtenerTextoISBN2(codigo:String) {
        let consulta = NSMutableURLRequest(URL: NSURL(string: "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + codigo)!)
        let sesion = NSURLSession.sharedSession()
        consulta.HTTPMethod = "GET"
        
        
        let entidadLibro = NSEntityDescription.entityForName("Libro", inManagedObjectContext: self.contexto!)
        let peticion = entidadLibro?.managedObjectModel.fetchRequestFromTemplateWithName("petLibro", substitutionVariables: ["isbn" : codigo])
        
        do {
            let entidadLibro2 = try self.contexto?.executeFetchRequest(peticion!)
            if (entidadLibro2?.count > 0){
                libroYaBuscado = true            }
        
        }
        catch{
            
        }
        
        let task = sesion.dataTaskWithRequest(consulta, completionHandler: {data, respuesta, error -> Void in
            if let datosRespuesta = respuesta as? NSHTTPURLResponse {
                if datosRespuesta.statusCode == 200 {
                    if data != nil {
                        self.texto = String(data: data!, encoding: NSUTF8StringEncoding)!
                        if self.texto == "{}" {
                            self.texto = ""
                            self.codigoError = 2
                        } else {
                            
                            do {
                                let jsonCompleto = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves)
                                let json = jsonCompleto as! NSDictionary
                     
                                let nombreJSON = "ISBN:" + codigo
                                
                                if let nombreTemp = json[nombreJSON]!["title"] as? String {
                                    self.tituloLibro = nombreTemp
                                }
                                
                                if let listaAutores = json[nombreJSON]!["authors"] as? NSArray {
                                    let autorDeLista = listaAutores[0] as! NSDictionary
                                    self.autores = autorDeLista["name"]! as! String
                                    if listaAutores.count > 1 {
                                        for var i = 1; i < listaAutores.count; i++ {
                                            self.autores = self.autores + "; " + (listaAutores[i]["name"]! as! String)
                                        }
                                    }
                                    self.autores = self.autores + "."
                                }
                                
                                if let portadasLibro = json[nombreJSON]!["cover"] as? NSDictionary {
                                    self.urlPortada = portadasLibro["medium"]! as! String
                                }
                            }
                            catch _ {
                                
                            }
                            
                            
                        }
                    }
                    else {
                        print(error?.localizedDescription)
                        self.codigoError = 2
                    }
                }
                else {
                    self.codigoError = 1
                }
            }
            else {
                self.codigoError = 1
            }
            self.refrescaPantalla()
        })
        task.resume()
    }
    
    func refrescaPantalla() {
        dispatch_async(dispatch_get_main_queue(), {
            self.etiquetaNombreLibro.text = self.tituloLibro
            self.etiquetaAutores.text = self.autores
            self.indicadorActividad.stopAnimating()
            
            let urlImagen = NSURL(string: self.urlPortada)
            let datosImagen = NSData(contentsOfURL: urlImagen!)
            if datosImagen != nil {
                self.imagenPortada.image = UIImage(data: datosImagen!)
            }
            
            if self.codigoError == 1 {
                let alerta = UIAlertController(title: "Conexión al Internet", message: "No hay servicio de internet", preferredStyle: UIAlertControllerStyle.Alert)
                alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
                    self.codigoISBN.text = ""
                }))
                self.presentViewController(alerta, animated: true, completion: nil)
            } else if self.codigoError == 2 {
                let alerta = UIAlertController(title: "Error en la búsqueda", message:
                    "No existe libro con codigo \(self.codigoISBN.text!)", preferredStyle: .Alert)
                alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
                    self.codigoISBN.text = ""
                }))
                self.presentViewController(alerta, animated: true, completion: nil)
            } else if self.codigoError == 0 {
                // Agregar el item en listadoLibros
                if self.opcion == 1 {
                  listadoLibros.append(self.codigoISBN.text!)
                    
                    if (!self.libroYaBuscado){
                        let nuevaEntidadLibro = NSEntityDescription.insertNewObjectForEntityForName("Libro", inManagedObjectContext: self.contexto!)
                        nuevaEntidadLibro.setValue(self.codigoISBN.text!, forKey: "isbn")
                        nuevaEntidadLibro.setValue(self.autores, forKey: "autores")
                        nuevaEntidadLibro.setValue(self.tituloLibro, forKey: "titulo")
                        
                        
                        do {
                            try self.contexto?.save()
                        } catch {
                            
                        }
                    }
                }
            }
            return
        })
    }
    
    
    func configureView() {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicadorActividad.stopAnimating()
        self.contexto = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

        if opcion == 0 {
            self.configureView()
            codigoISBN.hidden = true
            buscaCodigo(libroBuscado)
            
            
        } else if opcion == 1 {
            codigoISBN.hidden = false
            borraTodo()
            codigoISBN.becomeFirstResponder()
            
        }
    }
    
    var detailItem: AnyObject? {
        didSet {
            self.configureView()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}