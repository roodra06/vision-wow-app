//
//  HistorialCotizacionesView.swift
//  VisionWow — Módulo de Cotizaciones
//
//  Lista de todas las cotizaciones guardadas.
//  Permite ver el detalle, regenerar el PDF y eliminar.
//

import SwiftUI

struct HistorialCotizacionesView: View {

    @ObservedObject private var storage = CotizacionStorage.shared

    @State private var busqueda             = ""
    @State private var mostrarAlerta        = false
    @State private var idAEliminar: UUID?   = nil
    @State private var cotizacionAEditar: Cotizacion? = nil
    @State private var navegarAEditar       = false

    // Formateadores
    private let mxn: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle           = .currency
        f.currencyCode          = "MXN"
        f.currencySymbol        = "$"
        f.maximumFractionDigits = 0   // sin centavos en el listado
        return f
    }()	
    private let fechaFormato: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        f.locale     = Locale(identifier: "es_MX")
        return f
    }()

    // Cotizaciones filtradas por búsqueda
    private var filtradas: [Cotizacion] {
        let termino = busqueda.trimmingCharacters(in: .whitespaces).lowercased()
        guard !termino.isEmpty else { return storage.cotizaciones }
        return storage.cotizaciones.filter {
            $0.folio.lowercased().contains(termino) ||
            $0.cliente.nombreEmpresa.lowercased().contains(termino) ||
            $0.cliente.nombreContacto.lowercased().contains(termino)
        }
    }

    private func formatear(_ valor: Double) -> String {
        mxn.string(from: NSNumber(value: valor)) ?? "$0"
    }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                barraBusqueda
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    if storage.cotizaciones.isEmpty {
                        estadoVacio
                            .padding(.horizontal, 16)
                    } else {
                        listaCard
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationTitle("Historial de Cotizaciones")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navegarAEditar) {
            if let cot = cotizacionAEditar {
                NuevaCotizacionView(editando: cot)
            }
        }
        .alert("Eliminar cotización", isPresented: $mostrarAlerta) {
            Button("Eliminar", role: .destructive) {
                if let id = idAEliminar {
                    storage.eliminar(id: id)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }

    // MARK: - Barra de búsqueda

    private var barraBusqueda: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar por folio, empresa o contacto…", text: $busqueda)
                .autocorrectionDisabled()
        }
        .padding(10)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        SectionCard(title: "Sin cotizaciones", subtitle: nil) {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(BrandColors.primary.opacity(0.5))
                Text("Aún no has guardado ninguna cotización.\nCrea una y presiona \"Guardar en historial\".")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Lista de cotizaciones

    private var listaCard: some View {
        SectionCard(
            title: "Cotizaciones",
            subtitle: filtradas.isEmpty
                ? "Sin resultados"
                : "\(filtradas.count) de \(storage.cotizaciones.count) registro(s)"
        ) {
            if filtradas.isEmpty {
                Text("No se encontraron coincidencias.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filtradas.enumerated()), id: \.element.id) { idx, cot in
                        NavigationLink {
                            // Al ver desde historial, la cotización ya está guardada
                            ResumenCotizacionView(cotizacion: cot, yaGuardada: true)
                        } label: {
                            filaCotizacion(cot)
                        }
                        .buttonStyle(.plain)

                        Divider().opacity(0.2)
                    }
                }
            }
        }
    }

    // MARK: - Fila de cotización

    private func filaCotizacion(_ cot: Cotizacion) -> some View {
        HStack(spacing: 12) {
            // Icono del paquete
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: iconoPaquete(cot.paquete))
                    .font(.system(size: 16))
                    .foregroundStyle(BrandColors.primary)
            }

            // Datos principales
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(cot.folio)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(cot.paquete.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Text(cot.cliente.nombreEmpresa)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text("\(cot.cliente.nombreContacto)  •  \(cot.numeroColaboradores) colaboradores")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Total + fecha + swipe-delete
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatear(cot.totalFinal))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BrandColors.primary)
                Text(fechaFormato.string(from: cot.fechaEmision))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    // Botón editar
                    Button {
                        cotizacionAEditar = cot
                        navegarAEditar    = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(BrandColors.primary)
                    }
                    .buttonStyle(.plain)

                    // Botón eliminar
                    Button {
                        idAEliminar  = cot.id
                        mostrarAlerta = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(BrandColors.danger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Helper: icono según paquete

    private func iconoPaquete(_ paquete: Paquete) -> String {
        switch paquete {
        case .esencial:       return "eye"
        case .plus:           return "eye.circle"
        case .wowCorporativo: return "eye.circle.fill"
        case .servicioDiario: return "calendar.badge.clock"
        case .personalizado:  return "slider.horizontal.3"
        }
    }
}
