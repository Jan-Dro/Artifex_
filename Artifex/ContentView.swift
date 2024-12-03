//
//  ContentView.swift
//  Artifex
//
//  Created by Jesus Alejandro on 11/30/24.
//

//import SwiftUI
import CoreData

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
//                    } label: {
//                        Text(item.timestamp!, formatter: itemFormatter)
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { items[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//}
//
//private let itemFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .medium
//    return formatter
//}()
//
//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}


import SwiftUI

struct ContentView: View {
    @State private var lines: [[CGPoint]] = []
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            // Button container
            HStack {
                Button(action: clearCanvas) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: saveDrawing) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: shareDrawing) {
                    Text("Share")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            
            // Drawing canvas container
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 4)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    .padding(.horizontal, 20)

                DrawingCanvasView(lines: $lines)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Saved"),
                message: Text("Your drawing has been saved."),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func clearCanvas() {
        lines.removeAll()
        if let metalView = getMetalView() {
            metalView.clearCanvas()
        }
    }
    
    func saveDrawing() {
        if let metalView = getMetalView(), let image = metalView.snapshot() {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showAlert = true
        }
    }
    
    func shareDrawing() {
        if let metalView = getMetalView(), let image = metalView.snapshot() {
            let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = keyWindow.rootViewController {
                rootViewController.present(activityController, animated: true, completion: nil)
            } else {
                print("Unable to find the root view controller.")
            }
        }
        struct PegboardBackground: View {
            let rows = 100
            let columns = 60
            let spacing: CGFloat = 20
            let pegRadius: CGFloat = 2
            
            @Environment(\.colorScheme) var colorScheme
            var pegColor: Color {
                colorScheme == .dark ? .white : .black
            }
            var backgroundColor: Color {
                colorScheme == .dark ? .black : .white
            }

            var body: some View {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    ZStack {
                        backgroundColor
                            .edgesIgnoringSafeArea(.all)
                        
                        Canvas { context, size in
                            for rowIndex in 0..<rows {
                                for colIndex in 0..<columns {
                                    let x = CGFloat(colIndex) * spacing
                                    let y = CGFloat(rowIndex) * spacing
                                    
                                    if x < width && y < height {
                                        let circle = Path(ellipseIn: CGRect(
                                            x: x,
                                            y: y,
                                            width: pegRadius * 2,
                                            height: pegRadius * 2
                                        ))
                                        context.fill(circle, with: .color(pegColor))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getMetalView() -> MetalView? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        
        if let rootVC = keyWindow?.rootViewController {
            return findMetalView(in: rootVC.view)
        }
        return nil
    }
    
    func findMetalView(in view: UIView) -> MetalView? {
        if let metalView = view as? MetalView {
            return metalView
        }
        for subview in view.subviews {
            if let found = findMetalView(in: subview) {
                return found
            }
        }
        return nil
    }
}
